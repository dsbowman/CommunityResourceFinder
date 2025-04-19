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
import FirebaseFirestore

class DetailViewModel: ObservableObject {
    private let db = Firestore.firestore()
    @Published var isShowingIssueForm = false
    @Published var position = MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        )
    
    func upadateLocation(resourceID: String, lat: Double, lon: Double) {
        print("Updating \(resourceID) to lat: \(lat), lon: \(lon)")
        let resourceRef = db.collection("resources").document(resourceID)
        resourceRef.updateData([
            "primaryLocationLat" : lat,
            "primaryLocationLon" : lon
        ])
    }
    
}

