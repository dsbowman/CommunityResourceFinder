//
//  NetworkManager.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import Foundation
import UIKit

final class NetworkManager {
    
    static let shared = NetworkManager()
    private let cache = NSCache<NSString, UIImage>()
    
    private let baseURL = "https://api.airtable.com/v0/appG874fGad8U9K7y/CommunityResources"
    private let authorizationToken = "Bearer pat9oBQHMYP0D8ZqG.6a33616f8677ee3534fc7c6e45dced6f1b3f42690446b31abcaff961c852ce6f"
    
    private init() {}
    
    func getData(offset: String? = nil) async throws -> (records: [Record], nextOffset: String?) {
            // Construct the URL with offset if provided
            var urlString = baseURL
            if let offset = offset {
                urlString += "?offset=\(offset)"
            }

            guard let url = URL(string: urlString) else {
                throw RFError.invalidURL
            }

            var request = URLRequest(url: url)
            request.setValue(authorizationToken, forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw RFError.invalidResponse
            }

            do {
                let decoder = JSONDecoder()
                let communityResourceModel = try decoder.decode(CommunityResourceModel.self, from: data)
                let nextOffset = communityResourceModel.offset // Airtable might provide the next offset
                return (communityResourceModel.records, nextOffset)
            } catch {
                throw RFError.invalidData // More specific error for decoding issues
            }
        }

    func downloadImage(fromURLString urlString: String, completed: @escaping (UIImage?) -> Void) {
        
        let cacheKey = urlString
        
        if let image = cache.object(forKey: cacheKey as NSString) {
            completed(image)
            return
        }
        
        guard let url = URL(string: urlString) else {
            completed(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) {[cacheKey] data, response, error in
            
            guard let data = data, let image = UIImage(data: data) else {
                completed(nil)
                return
            }
            self.cache.setObject(image, forKey: cacheKey as NSString)
            completed(image)
        }
        
        task.resume()
    }
    
}
    

