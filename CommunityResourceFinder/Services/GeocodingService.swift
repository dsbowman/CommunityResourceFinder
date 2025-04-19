//
//  GeocodingService.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 2/8/25.
//

import CoreLocation
import FirebaseFirestore
import Foundation

actor GeocodingService {
    // Singleton instance for shared access
    static let shared = GeocodingService()
    
    private let geocoder = CLGeocoder()
    private var activeRequests = 0
    private let maxConcurrentRequests = 10
    private let requestDelay: TimeInterval = 0.5  // Half second delay between requests
    
    private init() {}
    
    // Process a single location
    func geocodeLocation(street1: String?, street2: String?, city: String?, state: String?, zip: String?) async throws -> CLLocationCoordinate2D? {
        // Validate required fields
        guard let street1 = street1,
              let city = city,
              let state = state else {
            throw GeocodingError.missingRequiredFields
        }
        
        // Construct address string
        let address = [
            street1,
            street2,
            city,
            state,
            zip
        ].compactMap { $0 }.joined(separator: ", ")
        
        // Rate limiting check
        while activeRequests >= maxConcurrentRequests {
            try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
        }
        
        activeRequests += 1
        defer { activeRequests -= 1 }
        
        do {
            // Add slight delay to prevent rate limiting
            try await Task.sleep(nanoseconds: UInt64(requestDelay * Double(NSEC_PER_SEC)))
            
            let placemarks = try await geocoder.geocodeAddressString(address)
            
            guard let location = placemarks.first?.location?.coordinate else {
                throw GeocodingError.noLocationFound
            }
            
            return location
        } catch {
            throw GeocodingError.geocodingFailed(error)
        }
    }
    
    // Process a batch of locations with progress tracking
    func processLocations(_ locations: [(id: String, address: ResourceAddress)],
                         progressUpdate: @escaping (Double) -> Void) async -> [String: GeocodingResult] {
        var results: [String: GeocodingResult] = [:]
        let total = Double(locations.count)
        
        // Process locations in smaller batches to manage rate limiting
        let batchSize = 20
        for batch in stride(from: 0, to: locations.count, by: batchSize) {
            let end = min(batch + batchSize, locations.count)
            let currentBatch = Array(locations[batch..<end])
            
            await withTaskGroup(of: (String, GeocodingResult).self) { group in
                for location in currentBatch {
                    group.addTask {
                        do {
                            if let coordinate = try await self.geocodeLocation(
                                street1: location.address.street1,
                                street2: location.address.street2,
                                city: location.address.city,
                                state: location.address.state,
                                zip: location.address.zip
                            ) {
                                return (location.id, .success(coordinate))
                            } else {
                                return (location.id, .failure(.noLocationFound))
                            }
                        } catch {
                            return (location.id, .failure(.geocodingFailed(error)))
                        }
                    }
                }
                
                for await (id, result) in group {
                    results[id] = result
                    progressUpdate(Double(results.count) / total)
                }
            }
            
            // Add delay between batches
            try? await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        }
        
        return results
    }
    
    // Convert geocoding results to Firestore data
    func prepareForFirestore(_ results: [String: GeocodingResult]) -> [String: Any] {
        var firestoreData: [String: Any] = [:]
        
        for (id, result) in results {
            switch result {
            case .success(let coordinate):
                firestoreData[id] = [
                    "latitude": coordinate.latitude,
                    "longitude": coordinate.longitude,
                    "geopoint": GeoPoint(latitude: coordinate.latitude,
                                       longitude: coordinate.longitude),
                    "status": "success"
                ]
            case .failure(let error):
                firestoreData[id] = [
                    "error": error.localizedDescription,
                    "status": "failed"
                ]
            }
        }
        
        return firestoreData
    }
}

// Supporting types
struct ResourceAddress {
    let street1: String?
    let street2: String?
    let city: String?
    let state: String?
    let zip: String?
}

enum GeocodingError: LocalizedError {
    case missingRequiredFields
    case noLocationFound
    case geocodingFailed(Error)
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredFields:
            return "Missing required address fields"
        case .noLocationFound:
            return "No location found for address"
        case .geocodingFailed(let error):
            return "Geocoding failed: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Too many geocoding requests"
        }
    }
}

enum GeocodingResult {
    case success(CLLocationCoordinate2D)
    case failure(GeocodingError)
}
