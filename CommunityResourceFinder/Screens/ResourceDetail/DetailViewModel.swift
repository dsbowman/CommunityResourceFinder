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
    @Published var image: UIImage?
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
    
    //MARK: Create VCard
    
    func createVCardFile(resource: Resource) -> URL {
        
        let formattedAddress: String
        
        if let street1 = resource.primaryLocation?.street1,
           let city = resource.primaryLocation?.city,
           let state = resource.primaryLocation?.state,
           let zip = resource.primaryLocation?.zip
        {
            formattedAddress = ";;"+street1+";"+city+";"+state+";"+zip
        } else {
            formattedAddress = ";;;;;"
        }
        
        let vCardString =
             """
             BEGIN:VCARD
             VERSION:3.0
             N:\(resource.label)
             FB:\(resource.label)
             ORG:\(resource.label)
             TEL;TYPE=WORK,VOICE:\(resource.mainPhone ?? "")
             TEL;TYPE=EMERGENCY,VOICE:\(resource.emergencyPhone ?? "")
             EMAIL;TYPE=WORK:\(resource.generalEmail ?? "")
             URL:\(resource.url ?? "")
             ADR;TYPE=WORK:;;\(formattedAddress)
             NOTE:\(resource.description ?? "")
             END:VCARD
             """
        
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent("\(resource.label).vcf")
        
        do {
            try vCardString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating vCard file: \(error)")
            return tempDirectoryURL.appendingPathComponent("contact.vcf")
        }
        
    }
    
    func loadImage(from path: String) async {
        do {
            image = try await FirebaseImageService.shared.loadImage(from: path)
        } catch {
            print("Error loading image: \(error.localizedDescription)")
        }
    }
    
}

