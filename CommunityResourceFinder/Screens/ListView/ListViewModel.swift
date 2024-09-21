//
//  ListViewModel.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
import MapKit
import CoreLocation
import FirebaseCore

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
    private var currentOffset: String? = nil
    private var hasMoreData = true
    private var isFetchingData = false // Prevent multiple concurrent fetches
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 350))]
    
    var approvedResources: [Record] {
        resources.filter { $0.fields.status == "Active"}
    }
    
    var filteredResources: [Record] {
        guard !searchText.isEmpty else {return approvedResources}
        
        return approvedResources.filter { resource in
            resource.fields.label.localizedCaseInsensitiveContains(searchText) || resource.fields.descriptionNotes?.localizedCaseInsensitiveContains(searchText) ?? false || resource.fields.tags?.debugDescription.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    


    
    func getResources() {
        guard !isFetchingData && hasMoreData else { return }
        
        isLoading = true
        isFetchingData = true
        
        Task {
            do {
                let (newResources, nextOffset) = try await NetworkManager.shared.getData(offset: currentOffset)
                
                resources.append(contentsOf: newResources)
                currentOffset = nextOffset
                hasMoreData = nextOffset != nil
                
                fetchCoordinates(for: newResources)
                
            } catch {
                handleNetworkError(error)
            }
            isLoading = false  // Done loading
            isFetchingData = false
        }
        
    }
    
    
    private func handleNetworkError(_ error: Error) {
        if let RFError = error as? RFError {
            switch RFError {
                
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
        isLoading = false
    }
    
    
    func fetchCoordinates(for newResources: [Record]) {
        for i in 0..<newResources.count {
            let record = newResources[i]
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
                            self.calculateRegion()
                        }
                    } else {
                        print("No coordinates found for \(address)")
                    }
                }
            }
            
//            DispatchQueue.main.async {
//                self.calculateRegion()
//                self.isLoading = false  // Done loading
//            }

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
