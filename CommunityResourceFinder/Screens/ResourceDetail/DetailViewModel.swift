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
    @Published var vCardShareString: String = ""
    
    
    func upadateLocation(resourceID: String, lat: Double, lon: Double) {
        print("Updating \(resourceID) to lat: \(lat), lon: \(lon)")
        let resourceRef = db.collection("resources").document(resourceID)
        resourceRef.updateData([
            "primaryLocationLat" : lat,
            "primaryLocationLon" : lon
        ])
    }
    
    
    func createVCard(resource: Resource) -> String {
        
        let address: String
        
        if let street1 = resource.primaryLocation?.street1,
           let city = resource.primaryLocation?.city,
           let state = resource.primaryLocation?.state,
           let zip = resource.primaryLocation?.zip
        {
            address = "\(street1), \(city), \(state) \(zip)"
        } else {
            address = ""
        }
      
        return """
             BEGIN:VCARD
             VERSION:3.0
             ORG:\(resource.label)
             TEL;TYPE=WORK,VOICE:\(resource.mainPhone ?? "")
             TEL;TYPE=EMERGENCY,VOICE:\(resource.emergencyPhone ?? "")
             EMAIL;TYPE=WORK:\(resource.generalEmail ?? "")
             URL:\(resource.url ?? "")
             ADR;TYPE=WORK:;;\(address)
             NOTE:\(resource.description ?? "")
             END:VCARD
             """
    }
    
}

