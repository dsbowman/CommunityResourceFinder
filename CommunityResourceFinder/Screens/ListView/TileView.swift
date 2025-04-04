//
//  TileView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
import MapKit
import FirebaseCore
import FirebaseFirestore

struct TileView: View {
    
    @StateObject var viewModel = ListViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: viewModel.columns, spacing: 30) {ForEach(viewModel.filteredResources.sorted(by: {$0.label < $1.label }), id: \.id) { resource in
                        largeTile(resource: resource)
                            .accentColor(.primary)
                            .onTapGesture {
                                viewModel.selectedResource = resource
                                viewModel.isShowingDetail = true
                            }
                    }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Resources Finder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem {
                            Button {
                                viewModel.newResource = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                                    .fontWeight(.semibold)
                                    .tint(.softBlue)
                            }
                        }
                        
                    }
                    
                    .background(.ultraThinMaterial)
                    .task { viewModel.subscribeToResources()}
                    .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Resources") {
                        
                    }
//                                    .searchSuggestions{
//                                        Text("Food").searchCompletion("Food")
//                                        Text("Housing").searchCompletion("Housing")
//                                    }
                    .refreshable { viewModel.subscribeToResources()}
                    .background(Color("DarkNavy"))
                }
                
                
            }
            .overlay {
                if viewModel.filteredResources.isEmpty && viewModel.isLoading {
                    LoadingView()
                } else if viewModel.filteredResources.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
            .alert(item: $viewModel.alertItem) { alertItem in
                Alert(title: alertItem.title,
                      message: alertItem.message,
                      dismissButton: alertItem.dismissButton)
                
            }
            .sheet(isPresented: $viewModel.isShowingDetail) {
                if let selectedResource = viewModel.selectedResource {
                    Spacer().frame(height: 20)
                    DetailView(resource: selectedResource)
                        .presentationDragIndicator(.visible)
                }
            }
            
            
            
//            .sheet(isPresented: $viewModel.newResource) {
//                //            NewResourceView(newResource: $viewModel.newResource)
//                WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/paggA8fCAQVTEOrBT/form")!)
//                    .presentationDragIndicator(.visible)
//            }
            //        .onAppear {
            //            viewModel.testFirestoreConnection()
            //        }
            
        }
        
    }
}

    #Preview {
        TileView()
    }
    
    struct TileScrollView: View {
        
        var viewModel:ListViewModel
        
        var body: some View {
            ScrollView {
                LazyVGrid(columns: viewModel.columns, spacing: 30) {ForEach(viewModel.filteredResources.sorted(by: {$0.label < $1.label }), id: \.id) { resource in
                    largeTile(resource: resource)
                        .accentColor(.primary)
                        .onTapGesture {
                            viewModel.selectedResource = resource
                            viewModel.isShowingDetail = true
                        }
                }
                }
                .listStyle(.plain)
                .navigationTitle("Resources Finder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Button {
                            viewModel.newResource = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.semibold)
                                .tint(.softBlue)
                        }
                    }
                    
                }
                
                .background(.ultraThinMaterial)
            }
        }
        
        
    }
    
    struct ResourceMapView: View {
        
        var viewModel:ListViewModel
        
        @State private var settingsDetent = PresentationDetent.height(300)
        @State private var userPosition = MapCameraPosition.userLocation(fallback: .automatic)
        @State private var automaticPosition = MapCameraPosition.automatic
        @StateObject private var locationServices = LocationService()
        @State private var isShowingUserLocation = true
        
        var body: some View {
            
            VStack {
                Map(position: isShowingUserLocation ? $userPosition : $automaticPosition ) {
                    ForEach(viewModel.filteredResources) { resource in
                        if let location = resource.primaryLocation, let coordinate = location.coordinate {
                            Annotation(resource.label, coordinate: coordinate) {
                                Circle()
                                    .fill(.teal)
                                    .frame(width: 10, height: 10)
                                    .onTapGesture {
                                        viewModel.selectedResource = resource
                                        viewModel.isShowingDetail = true
                                        
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
                
                //            .sheet(isPresented: $viewModel.isShowingDetail) {
                ////                    Spacer().frame(height: 50).background(Color.white)
                //                if let selectedResource = viewModel.selectedResource {
                //                    DetailView(resource: selectedResource)
                //                        .presentationDetents([.height(270), .medium, .large], selection: $settingsDetent)
                //                        .presentationDragIndicator(.visible)
                //                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                //                }
                
            }
            //            .sheet(isPresented: $viewModel.isShowingList) {
            //                TileListView()
            //                    .presentationDetents([.height(300), .medium, .large], selection: $settingsDetent)
            //                    .presentationDragIndicator(.visible)
            //                    .presentationBackgroundInteraction(.enabled(upThrough: .large))
            //                    .presentationContentInteraction(.scrolls)
            //            }
            //            .sheet(isPresented: $viewModel.newResource) {
            //                //            NewResourceView(newResource: $viewModel.newResource)
            //                WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/paggA8fCAQVTEOrBT/form")!)
            //                    .presentationDragIndicator(.visible)
            //            }
            
        }
        
    }
    
