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
    private let appTestDebugToken = "A7E0279E-7BD3-4FDB-B479-824A118E32E8"
    
    
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
                       idMapping: [String: String],
                      progressUpdate: @escaping (Double) -> Void) async -> [String: ImageMigrationResult] {
        var results: [String: ImageMigrationResult] = [:]
        let total = Double(resources.count)
        
        let batchSize = 5
        
        for batchIndex in stride(from: 0, to: resources.count, by: batchSize) {
            let endIndex = min(batchIndex + batchSize, resources.count)
            let batch = Array(resources[batchIndex..<endIndex])
            
            await withTaskGroup(of: (String, ImageMigrationResult).self) { group in
                for resource in batch {
                    if let logoUrl = resource.fields.logo?.first?.url {
                        group.addTask {
                            do {
                                let newUrl = try await self.migrateImageWithRetry(
                                    from: logoUrl,
                                    resourceId: resource.id,
                                    maxRetries: 3
                                )
                                return (resource.id, .success(newUrl))
                            } catch {
                                return (resource.id, .failure(error))
                                
                            }
                        }
                    }
                }
                for await (resourceId, result) in group {
                    results[resourceId] = result
                }
            }
            
            progressUpdate(Double(min(endIndex, resources.count)) / total)
            
            if endIndex < resources.count {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        
//        for (index, resource) in resources.enumerated() {
//            if let logoUrl = resource.fields.logo?.first?.url {
//                do {
//                    let newUrl = try await migrateImage(
//                        from: logoUrl,
//                        resourceId: resource.id
//                    )
//                    results[resource.id] = .success(newUrl)
//                } catch {
//                    results[resource.id] = .failure(error)
//                }
//            }
//            
//            // Update progress
//            progressUpdate(Double(index + 1) / total)
//        }
        
        return results
    }
    
    private func migrateImageWithRetry(from airtableUrl: String, resourceId: String, maxRetries: Int) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await migrateImage(from: airtableUrl, resourceId: resourceId)
            } catch {
                lastError = error
                print("Image migration attempt \(attempt) failed for \(resourceId): \(error.localizedDescription)")
                
                // Exponential backoff - wait longer between each retry
                let delaySeconds = Double(attempt) * 0.5
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? ImageMigrationError.uploadFailed
    }
    
    
    // Update Firestore with new image URLs
    func updateFirestoreImages(_ results: [String: ImageMigrationResult], idMapping: [String: String]) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()
        
        for (airtableId, result) in results {
            // Use the mapping to get the Firestore document ID
            guard let firestoreId = idMapping[airtableId] else {
                print("Warning: No Firestore ID found for Airtable ID: \(airtableId)")
                continue
            }
            
            let resourceRef = db.collection("resources").document(firestoreId)
            
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
