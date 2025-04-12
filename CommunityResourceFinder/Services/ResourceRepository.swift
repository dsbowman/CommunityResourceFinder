////
////  ResourceRepository.swift
////  CommunityResourceFinder
////
////  Created by Deke Bowman on 3/30/25.
////
//
//import FirebaseFirestore
//import Combine
//import FirebaseStorage
//
//class ResourceRepository: ObservableObject {
//    private let db = Firestore.firestore()
//    private let storage = Storage.storage()
//    
//    // MARK: - Read Operations
//    
//    func getResources() async throws -> [Resource] {
//        let snapshot = try await db.collection("resources").getDocuments()
//        return try snapshot.documents.compactMap { document in
//            try document.data(as: Resource.self)
//        }
//    }
//    
//    func getResource(id: String) async throws -> Resource? {
//        let document = try await db.collection("resources").document(id).getDocument()
//        return try document.data(as: Resource.self)
//    }
//
//    // MARK: - Write Operations
//    
//    func addResource(_ resource: Resource) async throws -> String {
//        let documentRef = db.collection("resources").document()
//        try documentRef.setData(from: resource)
//        
//        // Add subcollections
//        if let locations = resource.locations {
//            for location in locations {
//                let locationRef = documentRef.collection("locations").document()
//                try locationRef.setData(from: location)
//            }
//        }
//        
//        if let contacts = resource.contacts {
//            for contact in contacts {
//                let contactRef = documentRef.collection("contacts").document()
//                try contactRef.setData(from: contact)
//            }
//        }
//        
//        return documentRef.documentID
//    }
//    
//    func updateResource(_ resource: Resource) async throws {
//        guard let id = resource.id else {
//            throw NSError(domain: "ResourceRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Resource ID is missing"])
//        }
//        
//        let documentRef = db.collection("resources").document(id)
//        try documentRef.setData(from: resource)
//    }
//    
//    func deleteResource(id: String) async throws {
//        try await db.collection("resources").document(id).delete()
//    }
//    
//    // MARK: - Image Operations
//    
//    func uploadImage(for resourceId: String, imageData: Data) async throws -> String {
//        let path = "resource_images/\(resourceId)/logo.jpg"
//        let storageRef = storage.reference().child(path)
//        
//        let metadata = StorageMetadata()
//        metadata.contentType = "image/jpeg"
//        
//        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
//        let downloadURL = try await storageRef.downloadURL()
//        
//        return downloadURL.absoluteString
//    }
//}
