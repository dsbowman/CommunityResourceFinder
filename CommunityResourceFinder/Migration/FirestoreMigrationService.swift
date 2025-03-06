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
    
    
    
//    // This function will be our main entry point
//    func migrateResources(from airtableRecords: [Record]) async throws {
//        // We'll use a batch write to ensure atomic operations
//        let batch = db.batch()
//        
//        for record in airtableRecords {
//            let resource = try convertToFirestoreResource(from: record)
//            
//            // Create a new document reference with auto-generated ID
//            let docRef = db.collection("resources").document()
//            
//            // Add the document to our batch
//            try batch.setData(from: resource, forDocument: docRef)
//        }
//        
//        // Commit the batch
//        try await batch.commit()
//    }
  
//    func migrateResources(from airtableRecords: [Record]) async throws {
//        addLog("Starting migration with \(airtableRecords.count) resources")
//        
//        // Update UI state
//        migrationStatus = "Migration in progress"
//        currentOperation = "Preparing batch write"
//        migrationProgress = 0.1
//        
//        let batch = db.batch()
//        let totalResources = Double(airtableRecords.count)
//        var migratedCount = 0
//        
//        addLog("Created Firestore batch for writing")
//        
//        for (index, record) in airtableRecords.enumerated() {
//            do {
//                currentOperation = "Processing resource \(index + 1) of \(airtableRecords.count)"
//                addLog("Processing: \(record.fields.label)")
//                
//                let resource = try convertToFirestoreResource(from: record)
//                let docRef = db.collection("resources").document()
//                try batch.setData(from: resource, forDocument: docRef)
//                
//                migratedCount += 1
//                migrationProgress = Double(index + 1) / totalResources
//                addLog("✅ Processed resource: \(record.fields.label)")
//                
//            } catch {
//                addLog("❌ Error processing resource: \(record.fields.label) - \(error.localizedDescription)")
//                // Continue processing other records even if one fails
//            }
//        }
//        
//        // Verify we have resources to commit
//        guard migratedCount > 0 else {
//            migrationStatus = "Failed"
//            addLog("❌ No resources were successfully converted")
//            throw MigrationError.conversionFailed("No resources were successfully converted")
//        }
//        
//        // Commit the batch
//        do {
//            currentOperation = "Committing changes to Firestore"
//            addLog("Attempting to commit \(migratedCount) resources to Firestore")
//            
//            try await batch.commit()
//            
//            migrationProgress = 1.0
//            migrationStatus = "Completed"
//            currentOperation = "Successfully migrated \(migratedCount) resources"
//            addLog("✅ Successfully committed all resources to Firestore")
//            
//        } catch {
//            migrationStatus = "Failed"
//            addLog("❌ Error committing to Firestore: \(error.localizedDescription)")
//            throw MigrationError.commitFailed("Failed to commit to Firestore: \(error.localizedDescription)")
//        }
//    }
  
    
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
        
        // Now process resources and their subcollections
        currentOperation = "Processing resources"
        for (index, record) in airtableRecords.enumerated() {
            do {
                addLog("Processing: \(record.fields.label)")
                
                // Create the main resource document
                let resourceRef = db.collection("resources").document()
                let resource = try convertToFirestoreResource(from: record)
                
                // Main resource document data (without nested arrays)
                let resourceData: [String: Any] = [
                    "label": resource.label,
                    "description": resource.description ?? "",
                    "type": resource.type.rawValue,
                    "url": resource.url ?? "",
                    "mainPhone": resource.mainPhone ?? "",
                    "emergencyPhone": resource.emergencyPhone ?? "",
                    "generalEmail": resource.generalEmail ?? "",
                    "status": resource.status.rawValue,
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
            
            let imageResults = await ImageMigrationService.shared.migrateImages(resources: airtableRecords, progressUpdate: imageMigrationProcess)
            
            addLog("UpdatingFirestore with \(imageResults.count) image migration results")
            try await ImageMigrationService.shared.updateFirestoreImages(imageResults)
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











//import Foundation
//import Firebase
//import FirebaseFirestore
//import Observation
//
//
//@Observable
//class FirestoreMigrationService {
//    
//    var isMigrating: Bool = false
//    var migrationStatus: String = "Not Started"
//    var migrationProgress: Double = 0.0
//    var currentOperation: String = ""
//    
//    private let db: Firestore
//    
//    // Add the logger as a property of the main class
//        let logger = MigrationLogger()
//    
//    
//    init() {
//        // Initialize the database reference
//        self.db = Firestore.firestore()
//    }
//    
//    // Function for the migration
////    func startMigration(from airtableData: [String: Any]) async throws {
////        logger.log("Starting migration process")
////        updateStatus(to: "Starting migration process", progress: 0.0)
////        
////        // We'll migrate in a specific order to maintain data relationships:
////        // 1. Tags first (since resources reference them)
////        // 2. Resources (including their locations and contacts)
////        // 3. Users
////        // 4. Reviews (since they reference both resources and users)
////        logger.log("Beginning tag migration")
////        try await migrateTags(from: airtableData)
////        logger.logSuccess("Successfully completed tag migration")
////        
////        logger.log("beginning resource migration")
////        try await migrateResources(from: airtableData)
////        logger.logSuccess("successfully completed resource migration")
////        
////        
////        logger.logSuccess("Migration completed successfully")
////        updateStatus(to: "Migration complete", progress: 1.0)
////        
////        
////    }
//    
//    func startMigration(with resources: [Record]) async throws {
//        guard !isMigrating else {
//            migrationStatus = "Migration already in progress"
//            print("Migration already in progress")
//            return
//        }
//
//        isMigrating = true
//        migrationProgress = 0.0
//
//        defer {
//            isMigrating = false
//        }
//
//        do {
//            // Process the existing resources in a batch
//            try await migrateResourceBatch(resources)
//            updateStatus(to: "Migration completed successfully", progress: 1.0)
//        } catch {
//            updateStatus(to: "Migration failed: \(error.localizedDescription)")
//            print("Migration failed: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    
//    func migrateResourceBatch(_ resources: [Record]) async throws {
//        logger.log("Starting batch migration for \(resources.count) resources")
//        
//        for (index, resource) in resources.enumerated() {
//            do {
//                // Log resource being migrated
//                logger.log("Migrating resource \(index + 1) of \(resources.count): \(resource.id)")
//                
//                let resourceRef = db.collection("resources").document(resource.id)
//                let batch = db.batch()
//                
//                // Write main resource data
//                batch.setData([
//                    "label": resource.fields.label,
//                    "descriptionNotes": resource.fields.descriptionNotes ?? "",
//                    "status": resource.fields.status ?? "Active",
//                    "created_by": "",
//                    "logo": resource.fields.logo?.compactMap { $0.url }.first ?? "",
//                    "url": resource.fields.url ?? ""
//                ], forDocument: resourceRef)
//                
//                // Commit the main document batch
//                try await batch.commit()
//                logger.logSuccess("Successfully committed resource document for \(resource.id)")
//                
//                // Process subcollections
//                logger.log("Processing subcollections for resource \(resource.id)")
//                try await migrateLocationSubcollection(for: Record, resourceRef: resourceRef)
//                try await migrateContactsSubcollection(for: resource, resourceRef: resourceRef)
//                try await migrateTagsSubcollection(for: resource, resourceRef: resourceRef)
//                
//                // Update progress
//                let progress = Double(index + 1) / Double(resources.count)
//                updateStatus(to: "Migrated \(index + 1) of \(resources.count) resources", progress: progress)
//                
//            } catch {
//                // Log and rethrow error
//                logger.logError("Failed to migrate resource \(resource.id): \(error.localizedDescription)")
//                throw error
//            }
//        }
//        
//        logger.logSuccess("Completed batch migration for \(resources.count) resources")
//    }
//    
//    private func migrateTags(from data: [String: Any]) async throws {
//        updateStatus(to: "Migrating tags...", progress: 0.1)
//        
//        guard let tagsData = data["tags"] as? [[String: Any]] else {
//            throw MigrationError.invalidData("Tags data is not in expected format")
//            
//        }
//        
//        let batch = db.batch()
//        
//        for tagData in tagsData {
//            let tag = Tag(
//                id: tagData["id"] as? String ?? UUID().uuidString,
//                name: tagData["name"] as? String ?? ""
//            )
//            
//            // Get a reference to where we'll store this tag
//            let tagRef = db.collection("tags").document(tag.id ?? UUID().uuidString)
//            
//            // Add this write operation to our batch
//            try batch.setData( from: tag, forDocument: tagRef)
//            
//        }
//        
//        try await batch.commit()
//        
//        updateStatus(to: "Tags migration completed", progress: 0.25)
//        
//    }
//    
////    private func migrateResources(from data: [String: Any]) async throws {
////        // Log the start of resource processing
////        logger.log("Processing resource data")
////        
////        guard let resourcesData = data["resources"] as? [[String: Any]] else {
////            // Log when we encounter invalid data
////            logger.logError("Failed to parse resource data - invalid format")
////            throw MigrationError.invalidData("Resources data is not in the expected format")
////        }
////
////        // Log how many resources we're about to process
////        logger.log("Found \(resourcesData.count) resources to migrate")
////
////        for (index, resourceData) in resourcesData.enumerated() {
////            do {
////                // Log each resource as we process it
////                logger.log("Migrating resource \(index + 1) of \(resourcesData.count)")
////                
////                let resourceRef = db.collection("resources").document(resourceData["id"] as? String ?? UUID().uuidString)
////                let batch = db.batch()
////
////                // After setting up the main resource document
////                batch.setData([
////                    "created_by": "",
////                    "description": resourceData["description"] ?? "",
////                    "label": resourceData["label"] ?? "",
////                    // ... other fields ...
////                ], forDocument: resourceRef)
////
////                try await batch.commit()
////                logger.logSuccess("Successfully migrated resource document \(index + 1)")
////
////                // When starting subcollections
////                logger.log("Processing subcollections for resource \(index + 1)")
////                try await migrateLocationSubcollection(for: resourceData, resourceRef: resourceRef)
////                try await migrateContactsSubcollection(for: resourceData, resourceRef: resourceRef)
////                try await migrateTagsSubcollection(for: resourceData, resourceRef: resourceRef)
////                
////                logger.logSuccess("Completed all subcollections for resource \(index + 1)")
////
////            } catch {
////                // Log any errors that occur during processing
////                logger.logError("Failed to migrate resource \(index + 1): \(error.localizedDescription)")
////                throw error
////            }
////        }
////    }
//    
//    // Add this at the top of your FirestoreMigrationService class or in an extension
//    private struct FirestoreHours: Codable {
//        struct DayHours: Codable {
//            var day: String   // The day name
//            var open: String? // Opening time
//            var close: String? // Closing time
//        }
//        
//        var days: [DayHours]
//    }
//
//    // First, let's define our extension at the top level of the migration service
//    private extension Encodable {
//        func asDictionary() throws -> [String: Any] {
//            let data = try JSONEncoder().encode(self)
//            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
//                throw MigrationError.invalidData("Failed to convert object to dictionary")
//            }
//            return dictionary
//        }
//    }
//
//    // Then, in your location migration function, we'll modify how we handle the hours data
//    private func migrateLocationSubcollection(for resource: Record, resourceRef: DocumentReference) async throws {
//        logger.log("Starting location migration for resource")
//        
//        let locationCollectionRef = resourceRef.collection("Location")
//        
//        do {
//            // Create our hours structure
//            var operatingHours = FirestoreHours(days: [
//                .init(day: "Monday", open: nil, close: nil),
//                .init(day: "Tuesday", open: nil, close: nil),
//                .init(day: "Wednesday", open: nil, close: nil),
//                .init(day: "Thursday", open: nil, close: nil),
//                .init(day: "Friday", open: nil, close: nil),
//                .init(day: "Saturday", open: nil, close: nil),
//                .init(day: "Sunday", open: nil, close: nil)
//            ])
//            
//            // If there are existing hours, parse them
//            if let existingHours = resource.fields.hoursOfOperation {
//                try parseExistingHours(existingHours, into: &operatingHours)
//            }
//            
//            // Convert hours to dictionary format
//            let hoursDict = try operatingHours.asDictionary()
//            
//            let locationData: [String: Any] = [
//                "label": resource.fields.label,
//                "street1": resource.fields.street1 ?? "",
//                "street2": resource.fields.street2 ?? "",
//                "city": resource.fields.city ?? "",
//                "state": resource.fields.state ?? "",
//                "zip": resource.fields.zip ?? "",
//                "latitude": resource.fields.locationCoordinate?.latitude ?? 0.0,
//                "longitude": resource.fields.locationCoordinate?.longitude ?? 0.0,
//                "locationPhone": resource.fields.phoneContact2 ?? "",
//                "locationEmail": resource.fields.email ?? "",
//                "hoursOfOperation": hoursDict  // Use the converted dictionary here
//            ]
//            
//            // Create a new document in the Location subcollection
//            try await locationCollectionRef.document().setData(locationData)
//            logger.logSuccess("Successfully migrated location information")
//            
//        } catch {
//            logger.logError("Failed to migrate location information: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    
//    private func migrateContactsSubcollection(for resource: Record, resourceRef: DocumentReference) async throws {
//        logger.log("Starting contacts migration for resource")
//        
//        let contactsCollectionRef = resourceRef.collection("Contacts")
//        
//        do {
//            // Create a contact for each phone number/email combination
//            // You might need logic to determine which location ID to associate
//            let contactData: [String: Any] = [
//                "label": "Primary Contact", // You might want to make this more specific
//                "phone": resource.fields.phoneContact ?? "",
//                "email": resource.fields.email ?? "",
//                "role": "", // You'll need to determine how to set this
//                "locationId": nil // This would need to be set based on your logic
//            ]
//            
//            try await contactsCollectionRef.document().setData(contactData)
//            logger.logSuccess("Successfully migrated contact information")
//        } catch {
//            logger.logError("Failed to migrate contact information: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    
//    private func migrateTagsSubcollection(for resource: [String: Any], resourceRef: DocumentReference) async throws {
//        // Log the start of tag migration
//        logger.log("Starting tags migration for resource")
//        
//        // Get a reference to the Tags subcollection
//        let tagsCollectionRef = resourceRef.collection("Tags")
//        
//        // Safely get the tags array from the resource
//        if let tags = resource["tags"] as? [String] {
//            // Log how many tags we found
//            logger.log("Found \(tags.count) tags to migrate")
//            
//            // Process each tag
//            for (index, tag) in tags.enumerated() {
//                do {
//                    // Create the tag document with just the label field
//                    let tagData = [
//                        "label": tag
//                    ]
//                    
//                    // Log which tag we're processing
//                    logger.log("Migrating tag \(index + 1) of \(tags.count)")
//                    
//                    // Create a new document in the Tags subcollection
//                    try await tagsCollectionRef.document().setData(tagData)
//                    
//                    // Log successful tag creation
//                    logger.logSuccess("Successfully migrated tag: \(tag)")
//                } catch {
//                    // If a specific tag fails, log it but continue with others
//                    logger.logWarning("Failed to migrate tag \(tag): \(error.localizedDescription)")
//                    // Note: We might want to continue rather than throw here to allow other tags to migrate
//                }
//            }
//            
//            // Log completion of all tags
//            logger.logSuccess("Completed migration of all \(tags.count) tags")
//        } else {
//            // Log if no tags were found
//            logger.logWarning("No tags found for this resource")
//        }
//    }
//    
//    
//    
//    private func updateStatus(to status: String, progress: Double) {
//        
//        migrationStatus = status
//        migrationProgress = progress
//        currentOperation = status
//    }
//        
//        
//        // Add a function to check if Firebase is properly configured
//        func verifyFirebaseSetup() async -> Bool {
//            
//            do {
//                _ = try await db.collection("_test_").document("_test_").getDocument()
//                return true
//            } catch {
//                print("Firebase verification failed: \(error)")
//                return false
//            }
//        }
//        
//        
//    
//    
//    enum MigrationError: Error {
//        case invalidData(String)
//        case migrationFailed(String)
//        case verificationFailed(String)
//    }
//}
//
//extension FirestoreMigrationService {
//    // The MigrationLogger class will manage all our logging operations
//    @Observable class MigrationLogger {
//        // This array stores all our log entries
//        var logs: [MigrationLogEntry] = []
//        
//        // This method adds new log entries with a default type of .info
//        func log(_ message: String, type: MigrationLogEntry.LogType = .info) {
//            // Create a new log entry with the current timestamp
//            let entry = MigrationLogEntry(
//                timestamp: Date(),
//                message: message,
//                type: type
//            )
//            
//            // Add the new entry to our logs array
//            logs.append(entry)
//        }
//        
//        // Convenience methods for different types of logs
//        func logSuccess(_ message: String) {
//            log(message, type: .success)
//        }
//        
//        func logError(_ message: String) {
//            log(message, type: .error)
//        }
//        
//        func logWarning(_ message: String) {
//            log(message, type: .warning)
//        }
//    }
//}
