//
//  MapView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

import SwiftUI
import MapKit

struct MapView: View {
    
    @ObservedObject var viewModel = ListViewModel()
    @State private var settingsDetent = PresentationDetent.medium
    @State private var userPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State private var automaticPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            )
    )
    @StateObject private var locationServices = LocationService()
    @State private var isShowingUserLocation = true
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Map(position: isShowingUserLocation ? $userPosition : $automaticPosition ) {
                    ForEach(viewModel.filteredResources) { resource in
                        if let location = resource.primaryLocation, let coordinate = location.coordinate {
                            Annotation(resource.label, coordinate: coordinate) {
                                Circle()
                                    .fill(.teal)
                                    .frame(width: 10, height: 10)
                                    .onTapGesture {
                                        viewModel.activeSheet = .resourceDetail(resource)
                                    }
                                    .frame(width: 30, height: 30)
                            }
                            
                        }
                    }
                    
                }
                .accentColor(.teal)
                .onAppear {
                    locationServices.checkIfLocationServicesIsEnabled()
                }
                .onChange(of: viewModel.searchText) { oldValue, newValue in
                    // If there's search text, disable user location tracking
                    if !newValue.isEmpty {
                        isShowingUserLocation = false
                        if let firstResource = viewModel.filteredResources.first,
                           let location = firstResource.primaryLocation,
                           let coordinate = location.coordinate {
                            automaticPosition = MapCameraPosition.region(
                                MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                )
                            )
                        }
                    } else {
                        isShowingUserLocation = true
                    }
                }
                .mapControls {
                    MapScaleView()
                    MapCompass()
                    MapPitchToggle()
                    MapUserLocationButton()
                }
                
                .sheet(item: $viewModel.activeSheet) { sheetType in
                    switch sheetType {
                    case .resourceDetail(let resource):
                        DetailView(resource: resource)
                            .presentationDetents([.medium, .large], selection: $settingsDetent)
                            .presentationDragIndicator(.visible)
                            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    
                    case .issueForm:
                        WebView(url: URL(string:  "https://airtable.com/appG874fGad8U9K7y/pag8d4CoJAscwVHcY/form")!)

                    case .NewResource:
                        WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/paggA8fCAQVTEOrBT/form")!)

                    case .webView(_):
                        WebView(url: URL(string: "https://www.resourcefinder.app/") ?? URL(string: "https://www.google.com")!)
                    }

                }
                
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Resources")
            .navigationTitle("Resources Finder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


//#Preview {
//    MapView()
//}

