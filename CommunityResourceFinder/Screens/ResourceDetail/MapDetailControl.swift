//
//  MapDetailControl.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/19/24.
//

import SwiftUI
import MapKit

struct MapDetailControl: View {
    
    var resourceData: Fields
    
    @State private var position = MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        )
    
    var body: some View {
        if let street1 = resourceData.street1, let city = resourceData.city, let state = resourceData.state {
            Section {
                HStack(alignment: .top) {
                    ZStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Map(position: $position) {
                                if let coordinate = resourceData.locationCoordinate {
                                    Annotation(resourceData.label, coordinate: coordinate) {
                                        Circle()
                                            .fill(.blue)
                                            .frame(width: 10, height: 10)
                                    }
                                }
                            }
                            .frame(height: 175)
                            .onAppear {
                                if let coordinate = resourceData.locationCoordinate {
                                    position = MapCameraPosition.region(MKCoordinateRegion(
                                        center: coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.003125, longitudeDelta: 0.003125)
                                    ))
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Location")
                                    .font(.caption)
                                Link(destination: URL(string: "http://maps.apple.com/?address=\(street1),\(city),\(state)")!, label: {
                                    HStack() {
                                        Text(street1)
                                        if let street2 = resourceData.street2 {
                                            Text(street2)}
                                        Text("\(city), \(state) \(resourceData.zip ?? "")")
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

#Preview {
    MapDetailControl(resourceData: MockData.sampleResource)
}
