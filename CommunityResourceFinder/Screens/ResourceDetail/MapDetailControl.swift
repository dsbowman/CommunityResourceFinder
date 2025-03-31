//
//  MapDetailControl.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/19/24.
//

import SwiftUI
import MapKit

struct MapDetailControl: View {
    
    var latitude: Double
    var longitude: Double
    var label: String
    var street1: String?
    var street2: String?
    var city: String?
    var state: String?
    var zip: String?
    
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    var body: some View {
        if let street1 = street1, let city = city, let state = state {
            Section {
                HStack(alignment: .top) {
                    ZStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Map(position: $position) {
                                Annotation(label, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) {
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .frame(height: 175)
                            .onAppear {
                                position = MapCameraPosition.region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                    span: MKCoordinateSpan(latitudeDelta: 0.003125, longitudeDelta: 0.003125)
                                ))
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Location")
                                    .font(.caption)
                                Link(destination: URL(string: "http://maps.apple.com/?address=\(street1),\(city),\(state)")!, label: {
                                    HStack() {
                                        Text(street1)
                                        if let street2 = street2 {
                                            Text(street2)}
                                        Text("\(city), \(state) \(zip ?? "")")
                                        Spacer()
                                    }
                                    .font(.subheadline)
                                    
                                })
                                
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(height: 35)
                            .padding(10)
                            
                        }
                        .background(.gray)
                        .cornerRadius(20)
                        .textSelection(.enabled)
                        .shadow(radius: 10)
                        
                        
                    }
                    
                }
                
            }
            
        }
    }
}
//
//#Preview {
//    MapDetailControl(resourceData: MockData.sampleResource)
//}
