//
//  LocationService.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
import MapKit

 class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager?
     @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.952583, longitude: -75.165222), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

     
    
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            
        } else {
            print("Alert: Check to make sure your location services are on.")
        }
    }
    
    
   private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
            
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Alert: Your location is constricted")
            case .denied:
                print("Alert: You have denied this app location permissions")
            case .authorizedAlways, .authorizedWhenInUse:
            region = MKCoordinateRegion(center: locationManager.location!.coordinate, latitudinalMeters: 0.05, longitudinalMeters: 0.05)
            @unknown default:
                break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }


    
}
