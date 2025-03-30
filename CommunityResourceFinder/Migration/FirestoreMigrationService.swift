//
//  FirestoreMigrationService.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/30/24.
//
//

import Firebase
import FirebaseFirestore

@Observable
class FirestoreMigrationService {
    
    var migrationProgress: Double = 0.0
    var migrationStatus: String = "Not Started"
    var currentOperation: String = "Waiting to start"
    
    // Add published logs array for UI display
    var migrationLogs: [String] = []
    
    private let db = Firestore.firestore()

    // Helper method to add timestamped logs
        private func addLog(_ message: String) {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let logMessage = "[\(timestamp)] \(message)"
            print(logMessage) // Print to console for debugging
            migrationLogs.append(logMessage)
        }
  
    
    func migrateResources(from airtableRecords: [Record]) async throws {
        addLog("Starting migration with \(airtableRecords.count) resources")
        migrationStatus = "Migration in progress"
        
        // First, let's handle tags. We'll collect all unique tags across resources
        currentOperation = "Processing tags"
        let allTags = Set(airtableRecords.compactMap { $0.fields.tags }.flatMap { $0 })
        
        // Create tags collection first
        for tag in allTags {
            do {
                let tagRef = db.collection("tags").document()
                try await tagRef.setData([
                    "name": tag,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                addLog("✅ Created tag: \(tag)")
            } catch {
                addLog("❌ Error creating tag: \(tag) - \(error.localizedDescription)")
            }
        }
        
        var idMapping: [String: String] = [:]
        
        // Now process resources and their subcollections
        currentOperation = "Processing resources"
        for (index, record) in airtableRecords.enumerated() {
            do {
                addLog("Processing: \(record.fields.label)")
                
                // Create the main resource document
                let resourceRef = db.collection("resources").document()
                let resource = try convertToFirestoreResource(from: record)
                
                idMapping[record.id] = resourceRef.documentID
                
                // Main resource document data (without nested arrays)
                let resourceData: [String: Any] = [
                    "label": resource.label,
                    "description": resource.description ?? "",
                    "type": resource.type.rawValue,
                    "url": resource.url ?? "",
                    "logoUrl": resource.logoUrl ?? "",
                    "mainPhone": resource.mainPhone ?? "",
                    "emergencyPhone": resource.emergencyPhone ?? "",
                    "generalEmail": resource.generalEmail ?? "",
                    "status": resource.status.rawValue,
                    "airtableId": record.id,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                // Write the main resource document
                try await resourceRef.setData(resourceData)
                addLog("✅ Created resource document: \(record.fields.label)")
                
                // Handle locations subcollection
                if let locations = resource.locations {
                    // Create an array to hold all our async tasks
                    let locationTasks = locations.map { location in
                        // Return an async task for each location
                        Task {
                            let locationRef = resourceRef.collection("locations").document()
                            try locationRef.setData(from: location)
                        }
                    }
                    
                    // Wait for all location tasks to complete
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        // Add all our tasks to the group
                        for task in locationTasks {
                            group.addTask { try await task.value }
                        }
                        // Wait for all tasks to complete
                        try await group.waitForAll()
                    }
                    addLog("✅ Created locations for: \(record.fields.label)")
                }

                // Handle contacts subcollection
                if let contacts = resource.contacts {
                    // Create an array to hold all our async tasks
                    let contactTasks = contacts.map { contact in
                        // Return an async task for each contact
                        Task {
                            let contactRef = resourceRef.collection("contacts").document()
                            try contactRef.setData(from: contact)
                        }
                    }
                    
                    // Wait for all contact tasks to complete
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        // Add all our tasks to the group
                        for task in contactTasks {
                            group.addTask { try await task.value }
                        }
                        // Wait for all tasks to complete
                        try await group.waitForAll()
                    }
                    addLog("✅ Created contacts for: \(record.fields.label)")
                }
                
                migrationProgress = Double(index + 1) / Double(airtableRecords.count)
                addLog("✅ Completed processing resource: \(record.fields.label)")
                
            } catch {
                addLog("❌ Error processing resource: \(record.fields.label) - \(error.localizedDescription)")
            }
        }
        
        currentOperation = "Migrating resource images"
        addLog("Starting image migration for \(airtableRecords.count) resources")
        
        let imageMigrationProcess = { (progress: Double) in
            
            self.migrationProgress = 0.7 + (progress * 0.3)
            self.currentOperation = "Processing resource images: \(Int(progress * 100))%"
            
        }
        
        do {
            
            let imageResults = await ImageMigrationService.shared.migrateImages(resources: airtableRecords, idMapping: idMapping, progressUpdate: imageMigrationProcess)
            
            addLog("UpdatingFirestore with \(imageResults.count) image migration results")
            try await ImageMigrationService.shared.updateFirestoreImages(imageResults, idMapping: idMapping)
            addLog("✅ Image migration completed successfully")
        } catch {
            addLog("❌ Error migrating images - \(error.localizedDescription)")  
        }
        
        migrationProgress = 1.0
        migrationStatus = "Completed"
        currentOperation = "Migration completed"
        addLog("✅ Migration completed successfully")
    }
    
    private func convertToFirestoreResource(from record: Record) throws -> Resource {
        let fields = record.fields
        
        let logoURL = fields.logo?.first?.url
        
        // First, let's handle the location since it contains address information
        let location = Resource.Location(
            id: nil,  // Firestore will generate this
            label: "Main Location", // Default label for single location
            street1: fields.street1,
            street2: fields.street2,
            city: fields.city,
            state: fields.state,
            zip: fields.zip,
            hoursOfOperation: parseHoursOfOperation(fields.hoursOfOperation),
            latitude: fields.locationCoordinate?.latitude,
            longitude: fields.locationCoordinate?.longitude,
            locationPhone: formatPhoneNumber(fields.phoneContact),
            locationEmail: fields.email
        )
        
        // Create contacts array with phoneContact2 as a separate contact
        var contacts: [Resource.Contact] = []
        if let phoneContact2 = fields.phoneContact2 {
            contacts.append(Resource.Contact(
                id: nil,  // Firestore will generate this
                label: "Additional Contact",
                phone: formatPhoneNumber(phoneContact2),
                email: nil,
                role: nil,
                locationId: nil
            ))
        }
        
        return Resource(
            id: nil,  // Firestore will generate this
            label: fields.label,
            description: fields.descriptionNotes,
            type: fields.type == .organization ? .organization : .program,
            url: fields.url,
            logoUrl: logoURL,
            tags: fields.tags,
            mainPhone: formatPhoneNumber(fields.phoneContact),
            emergencyPhone: formatPhoneNumber(fields.emergencyAssistanceNumber),
            generalEmail: fields.email,
            locations: [location],  // Add our created location
            contacts: contacts,     // Add our contacts array
            status: .active        // Default to active for migration
        )
    }
    
    // Helper function to parse hours string into our structured format
    private func parseHoursOfOperation(_ hoursString: String?) -> [Resource.HoursOfOperation] {
        guard let hoursString = hoursString else { return [] }
        
        // This is a simplified parser - you might want to enhance it based on your data
        let hours = Resource.HoursOfOperation(days: [
            Resource.HoursOfOperation.DayHours(
                day: .monday,
                open: "9:00",  // Default values - adjust based on your needs
                close: "17:00"
            )
        ])
        
        // Log that we're using default hours
        migrationLogs.append("Using default hours for string: \(hoursString)")
        
        return [hours]
    }
    
    // Helper function to format phone numbers
    private func formatPhoneNumber(_ phone: String?) -> String? {
        guard let phone = phone else { return nil }
        // Remove any non-numeric characters
        let numbers = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return numbers
    }
    
    enum MigrationError: LocalizedError {
        case conversionFailed(String)
        case commitFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .conversionFailed(let message): return "Conversion failed: \(message)"
            case .commitFailed(let message): return "Commit failed: \(message)"
            }
        }
    }
}
