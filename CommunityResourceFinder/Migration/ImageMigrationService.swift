//
//  ImageMigrationService.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 2/10/25.
//

import FirebaseStorage
import FirebaseFirestore
import UIKit

actor ImageMigrationService {
    // Singleton instance
    static let shared = ImageMigrationService()
    
    private let storage = Storage.storage()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    // Migrate a single image
    func migrateImage(from airtableUrl: String, resourceId: String) async throws -> String {
        // First download the image from Airtable
        guard let url = URL(string: airtableUrl) else {
            throw ImageMigrationError.invalidURL
        }
        
        // Download the image data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Verify we got an image
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let image = UIImage(data: data) else {
            throw ImageMigrationError.downloadFailed
        }
        
        // Optimize the image before upload
        guard let optimizedData = image.jpegData(compressionQuality: 0.7) else {
            throw ImageMigrationError.compressionFailed
        }
        
        // Create a unique path in Firebase Storage
        let storagePath = "resource_images/\(resourceId)/logo.jpg"
        let storageRef = storage.reference().child(storagePath)
        
        // Create metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload to Firebase Storage
        _ = try await storageRef.putDataAsync(optimizedData, metadata: metadata)
        
        // Get the download URL
        let downloadUrl = try await storageRef.downloadURL()
        
        return downloadUrl.absoluteString
    }
    
    // Migrate a batch of images
    func migrateImages(resources: [Record],
                      progressUpdate: @escaping (Double) -> Void) async -> [String: ImageMigrationResult] {
        var results: [String: ImageMigrationResult] = [:]
        let total = Double(resources.count)
        
        for (index, resource) in resources.enumerated() {
            if let logoUrl = resource.fields.logo?.first?.url {
                do {
                    let newUrl = try await migrateImage(
                        from: logoUrl,
                        resourceId: resource.id
                    )
                    results[resource.id] = .success(newUrl)
                } catch {
                    results[resource.id] = .failure(error)
                }
            }
            
            // Update progress
            progressUpdate(Double(index + 1) / total)
        }
        
        return results
    }
    
    // Update Firestore with new image URLs
    func updateFirestoreImages(_ results: [String: ImageMigrationResult]) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()
        
        for (resourceId, result) in results {
            let resourceRef = db.collection("resources").document(resourceId)
            
            switch result {
            case .success(let newUrl):
                batch.updateData([
                    "logoUrl": newUrl,
                    "imageStatus": "migrated"
                ], forDocument: resourceRef)
                
            case .failure(let error):
                batch.updateData([
                    "imageStatus": "failed",
                    "imageError": error.localizedDescription
                ], forDocument: resourceRef)
            }
        }
        
        try await batch.commit()
    }
}

// Supporting types
enum ImageMigrationError: LocalizedError {
    case invalidURL
    case downloadFailed
    case compressionFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .downloadFailed:
            return "Failed to download image"
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload to Firebase Storage"
        }
    }
}

enum ImageMigrationResult {
    case success(String)  // New Firebase Storage URL
    case failure(Error)   // What went wrong
}
