//
//  DetailViewModel.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class DetailViewModel: ObservableObject {
    
    @Published var isShowingIssueForm = false
    @Published var position = MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        )
    
//    @Published var alertItem: AlertItem?
//    @Published var isLoading = true
//    @Published var searchText: String = ""
//    @Published var isSheetPresented = true
//    @Published var mapRegion: MKCoordinateRegion? = nil // Make it optional
//    @Published var isShowingDetail = false
//    @Published var selectedResource: Fields?
//
//    func fetchCoordinates(record: Fields) {
//
//            let address = "\(record.street1 ?? ""), \(record.street2 ?? ""), \(record.city ?? ""), \(record.state ?? ""), \(record.zip ?? "")"
//
//            CLGeocoder().geocodeAddressString(address) { (placemarks, error) in
//                if let error = error {
//                    print("Geocoding error for \(address): \(error.localizedDescription)")
//                    return
//                }
//
//                if let placemark = placemarks?.first,
//                   let location = placemark.location {
//
//                    DispatchQueue.main.async { // Update on main thread
//                        self.record.locationCoordinate = location.coordinate
//                    }
//                } else {
//                    print("No coordinates found for \(address)")
//                }
//            }
//
//        DispatchQueue.main.async {
//            self.calculateRegion()
//            self.isLoading = false  // Done loading
//        }
//    }
//
//    func calculateRegion() {
//            var minLatitude = 90.0
//            var maxLatitude = -90.0
//            var minLongitude = 180.0
//            var maxLongitude = -180.0
//
//            for record in resources {
//                if let coordinate = record.fields.locationCoordinate {
//                    minLatitude = min(minLatitude, coordinate.latitude)
//                    maxLatitude = max(maxLatitude, coordinate.latitude)
//                    minLongitude = min(minLongitude, coordinate.longitude)
//                    maxLongitude = max(maxLongitude, coordinate.longitude)
//
//                }
//            }
//
//            let center = CLLocationCoordinate2D(
//                latitude: (minLatitude + maxLatitude) / 2,
//                longitude: (minLongitude + maxLongitude) / 2
//            )
//
//            let span = MKCoordinateSpan(
//                latitudeDelta: (maxLatitude - minLatitude) * 1.2,
//     // Add padding
//                longitudeDelta: (maxLongitude - minLongitude) * 1.2 // Add padding
//            )
//
//            mapRegion = MKCoordinateRegion(center: center, span: span)
//        }
//
    
    
}

