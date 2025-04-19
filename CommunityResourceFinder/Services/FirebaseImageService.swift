//
//  FirebaseImageService.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 3/30/25.
//

import FirebaseStorage
import UIKit
import SwiftUI

class FirebaseImageService {
    static let shared = FirebaseImageService()
    
    private let storage = Storage.storage()
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private init() {
        memoryCache.countLimit = 100
    }
    
    func loadImage(from path: String) async throws -> UIImage {
        // Check memory cache first
        let cacheKey = path as NSString
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskCachedImage = try? loadImageFromDisk(path: path) {
            // Store in memory cache for faster access next time
            memoryCache.setObject(diskCachedImage, forKey: cacheKey)
            return diskCachedImage
        }
        
        // Download from Firebase if not in cache
        let storageRef = storage.reference().child(path)
        
        // Enable offline capabilities with .allowingLowResolutionFetching
        let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
        
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: cacheKey)
        
        // Save to disk for offline use
        try saveImageToDisk(image: image, path: path)
        
        return image
    }
    
    // Disk cache methods
    private func loadImageFromDisk(path: String) throws -> UIImage? {
        let fileURL = try imageFileURL(for: path)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let imageData = try Data(contentsOf: fileURL)
        return UIImage(data: imageData)
    }
    
    private func saveImageToDisk(image: UIImage, path: String) throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let fileURL = try imageFileURL(for: path)
        
        // Create directory if needed
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        try data.write(to: fileURL)
    }
    
    private func imageFileURL(for path: String) throws -> URL {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }
        
        let imageDir = cacheDir.appendingPathComponent("FirebaseImages")
        // Create a file-system safe path
        let safePath = path.replacingOccurrences(of: "/", with: "_")
        return imageDir.appendingPathComponent(safePath)
    }
    
    // Clear cache methods
    func clearCache() {
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        
        let imageDir = cacheDir.appendingPathComponent("FirebaseImages")
        try? fileManager.removeItem(at: imageDir)
    }
}
