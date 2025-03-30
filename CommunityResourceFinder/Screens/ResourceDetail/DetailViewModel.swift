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
    
}

