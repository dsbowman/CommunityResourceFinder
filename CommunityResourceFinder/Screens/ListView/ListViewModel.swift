//
//  ListViewModel.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
import MapKit
import CoreLocation

@MainActor class ListViewModel: ObservableObject {
    
    @Published var resources: [Record] = []
    @Published var alertItem: AlertItem?
    @Published var isLoading = true
    @Published var searchText: String = ""
    @Published var isShowingList = true
    @Published var isShowingDetail = false
    @Published var selectedResource: Fields?
    @Published var newResource = false
    @Published var isSheetPresented = true
    @Published var mapRegion: MKCoordinateRegion? = nil // Make it optional
    private let locationManager = CLLocationManager() // Add location manager
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 350))]
    
    var filteredResources: [Record] {
        guard !searchText.isEmpty else {return resources}
        
        return resources.filter { resource in
            resource.fields.label.localizedCaseInsensitiveContains(searchText) || resource.fields.descriptionNotes?.localizedCaseInsensitiveContains(searchText) ?? false || resource.fields.tags?.debugDescription.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    

    
    func getResources() {
        isLoading = true
        Task {
            do {
                resources = try await NetworkManager.shared.getData()
            } catch {
                if let apError = error as? APError {
                    switch apError {
                        
                    case .invalidURL:
                        alertItem = AlertContext.invalidURL
                    case .invalidResponse:
                        alertItem = AlertContext.invalidResponse
                    case .invalidData:
                        alertItem = AlertContext.invalidData
                    case .unableToComplete:
                        alertItem = AlertContext.unableToComplete
                    }
                    
                } else {
                    alertItem = AlertContext.invalidResponse
                }
                alertItem = AlertContext.invalidResponse
                isLoading = false
            }
            fetchCoordinates() // Fetch coordinates after resources are loaded
            isLoading = false  // Done loading
        }
        
    }
    
    
    func fetchCoordinates() {
        for i in 0..<resources.count {
            let record = resources[i]
            if let street1 = record.fields.street1, let city = record.fields.city, let state = record.fields.state {
                
                let address = "\(street1), \(record.fields.street2 ?? ""), \(city), \(state), \(record.fields.zip ?? "")"
                
                CLGeocoder().geocodeAddressString(address) { (placemarks, error) in
                    if let error = error {
                        print("Geocoding error for \(address): \(error.localizedDescription)")
                        return
                    }

                    if let placemark = placemarks?.first,
                       let location = placemark.location {

                        DispatchQueue.main.async { // Update on main thread
                            self.resources[i].fields.locationCoordinate = location.coordinate
                        }
                    } else {
                        print("No coordinates found for \(address)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.calculateRegion()
                self.isLoading = false  // Done loading
            }

        }

    }
    
    func calculateRegion() {
            var minLatitude = 90.0
            var maxLatitude = -90.0
            var minLongitude = 180.0
            var maxLongitude = -180.0

            for record in resources {
                if let coordinate = record.fields.locationCoordinate {
                    minLatitude = min(minLatitude, coordinate.latitude)
                    maxLatitude = max(maxLatitude, coordinate.latitude)
                    minLongitude = min(minLongitude, coordinate.longitude)
                    maxLongitude = max(maxLongitude, coordinate.longitude)

                }
            }

            let center = CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            )

            let span = MKCoordinateSpan(
                latitudeDelta: (maxLatitude - minLatitude) * 1.2, // Add padding
                longitudeDelta: (maxLongitude - minLongitude) * 1.2 // Add padding
            )

            mapRegion = MKCoordinateRegion(center: center, span: span)
        }

}
