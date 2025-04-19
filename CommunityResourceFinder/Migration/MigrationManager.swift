////
////  MigrationManager.swift
////  CommunityResourceFinder
////
////  Created by Claude on 12/31/24.
////
//
//import Firebase
//import FirebaseFirestore
//import Observation
//
//@Observable
//class MigrationManager {
//    // State tracking
//    var migrationStatus: String = "Not Started"
//    var migrationProgress: Double = 0.0
//    var isMigrating = false
//    
//    // Services
//    private let networkManager = NetworkManager.shared
//    private let db = Firestore.firestore()
//    
//    // Pagination tracking
//    private var currentOffset: String? = nil
//    private var hasMoreData = true
//    
//    // This is our main entry point for starting the migration
//    func startMigration() async throws {
//        guard !isMigrating else {
//            migrationStatus = "Migration already in progress"
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
//        
//        do {
//            // Keep fetching and migrating until we have all data
//            while hasMoreData {
//                updateStatus(to: "Fetching next batch of resources")
//                
//                // Fetch a batch of records from Airtable
//                let (resources, nextOffset) = try await networkManager.getData(offset: currentOffset)
//                
//                // Process this batch
//                try await migrateResourceBatch(resources)
//                
//                // Update pagination tracking
//                currentOffset = nextOffset
//                hasMoreData = nextOffset != nil
//                
//                // Update progress (rough estimation)
//                migrationProgress = hasMoreData ? 0.5 : 1.0
//            }
//            
//            updateStatus(to: "Migration completed successfully")
//        } catch {
//            updateStatus(to: "Migration failed: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    private func migrateResourceBatch(_ resources: [Record]) async throws {
//        // We'll process each resource one at a time to maintain data integrity
//        for (index, resource) in resources.enumerated() {
//            let resourceRef = db.collection("resources").document(resource.id)
//            
//            // Start a batch write for the main document and its immediate fields
//            let batch = db.batch()
//            
//            // Set up the main resource document
//            // Notice we removed the 'try' here since setData() doesn't throw
//            batch.setData([
//                "created_by": "",
//                "description": resource.fields.descriptionNotes ?? "",
//                "label": resource.fields.label,
//                "logo": resource.fields.logo?.compactMap { $0.url }.first ?? "",
//                "status": resource.fields.status ?? "Active",
//                "url": resource.fields.url ?? ""
//            ], forDocument: resourceRef)
//            
//            // This is where we actually need the 'try' since commit() can throw
//            do {
//                try await batch.commit()
//            } catch let error as NSError where error.domain == FirestoreErrorDomain {
//                print("Firestore error: \(error.code), \(error.localizedDescription)")
//                // Handle specific Firestore errors
//            }
//            
//            // Now handle subcollections
//            try await migrateLocationSubcollection(for: resource, resourceRef: resourceRef)
//            try await migrateContactsSubcollection(for: resource, resourceRef: resourceRef)
//            try await migrateTagsSubcollection(for: resource, resourceRef: resourceRef)
//            
//            // Update progress for this resource
//            let progress = Double(index + 1) / Double(resources.count)
//            updateStatus(to: "Migrated resource \(index + 1) of \(resources.count)", progress: progress)
//        }
//    }
//    
//    private func migrateLocationSubcollection(for resource: Record, resourceRef: DocumentReference) async throws {
//            // Get a reference to the Location subcollection
//            let locationCollectionRef = resourceRef.collection("Location")
//            
//            // Create the hours of operation structure
//            let hoursOfOperation = createHoursOfOperation()
//            
//            // Create the location document
//            let locationData: [String: Any] = [
//                "city": resource.fields.city ?? "",
//                "state": resource.fields.state ?? "",
//                "street_1": resource.fields.street1 ?? "",
//                "street_2": resource.fields.street2 ?? "",
//                "zip": resource.fields.zip ?? "",
//                "label": resource.fields.label,
//                
//                // Handle coordinates
//                "latitude": resource.fields.locationCoordinate?.latitude ?? 1.1,
//                "longitude": resource.fields.locationCoordinate?.longitude ?? 1.1,
//                // Create a proper Firestore GeoPoint
//                "geo_location": GeoPoint(
//                    latitude: resource.fields.locationCoordinate?.latitude ?? 0,
//                    longitude: resource.fields.locationCoordinate?.longitude ?? 0
//                ),
//                
//                // Add the hours of operation structure
//                "hours_of_operation": hoursOfOperation
//            ]
//            
//            // Create a new document in the Location subcollection
//            try await locationCollectionRef.document().setData(locationData)
//        }
//
//        private func createHoursOfOperation() -> [String: [String: String]] {
//            // Create a structured map for business hours
//            let daysOfWeek = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
//            
//            var hoursMap: [String: [String: String]] = [:]
//            
//            // Initialize each day with empty strings for open and close times
//            for day in daysOfWeek {
//                hoursMap[day] = [
//                    "open": "",
//                    "close": ""
//                ]
//            }
//            
//            return hoursMap
//        }
//
//        private func migrateContactsSubcollection(for resource: Record, resourceRef: DocumentReference) async throws {
//            // Get a reference to the Contacts subcollection
//            let contactsCollectionRef = resourceRef.collection("Contacts")
//            
//            // Create the contact document
//            let contactData: [String: Any] = [
//                "email": resource.fields.email ?? "",
//                "label": resource.fields.label,
//                "phone": resource.fields.phoneContact ?? ""
//            ]
//            
//            // Create a new document in the Contacts subcollection
//            try await contactsCollectionRef.document().setData(contactData)
//        }
//
//        private func migrateTagsSubcollection(for resource: Record, resourceRef: DocumentReference) async throws {
//            let tagsCollectionRef = resourceRef.collection("Tags")
//            
//            if let tags = resource.fields.tags {
//                print("Processing tags for resource \(resource.id): \(tags)")
//                for tag in tags {
//                    let tagData = [
//                        "label": tag
//                    ]
//                    
//                    print("Writing tag: \(tagData)")
//                    try await tagsCollectionRef.document().setData(tagData)
//                }
//            } else {
//                print("No tags found for resource \(resource.id). Skipping.")
//            }
//        }
//
//        private func updateStatus(to status: String, progress: Double? = nil) {
//            migrationStatus = status
//            if let progress = progress {
//                migrationProgress = progress
//            }
//        }
//    
//}
