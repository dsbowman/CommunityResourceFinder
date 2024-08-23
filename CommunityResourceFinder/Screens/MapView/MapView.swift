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
    
    @StateObject private var viewModel = ListViewModel()
    @State private var settingsDetent = PresentationDetent.height(225)
    @State private var position = MapCameraPosition.userLocation(fallback: .automatic)
    @StateObject private var locationServices = LocationService()

    
    var body: some View {
        VStack {
            Map(position: $position) {
                ForEach(viewModel.filteredResources) { record in
                    if let coordinate = record.fields.locationCoordinate {
                        Annotation(record.fields.label, coordinate: coordinate) {
                            Circle()
                                .fill(.teal)
                                .frame(width: 10, height: 10)
                                .onTapGesture {
                                    viewModel.selectedResource = record.fields
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
            .sheet(isPresented: $viewModel.isShowingDetail) {
                Spacer().frame(height: 50)
                DetailView(apiData: viewModel.selectedResource ?? MockData.sampleResource)
                    .presentationDetents([.height(225), .medium, .large], selection: $settingsDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
//            .sheet(isPresented: $viewModel.isShowingList) {
//                TileListView()
//                    .presentationDetents([.height(300), .medium, .large], selection: $settingsDetent)
//                    .presentationDragIndicator(.visible)
//                    .presentationBackgroundInteraction(.enabled(upThrough: .large))
//                    .presentationContentInteraction(.scrolls)
//            }
            
        }
        .task {
            viewModel.getResources()
            viewModel.fetchCoordinates()
        }
    }
}


#Preview {
    MapView()
}

