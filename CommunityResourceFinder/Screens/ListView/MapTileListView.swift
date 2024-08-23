//
//  MapTileListView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/23/24.
//

import SwiftUI

struct MapTileListView: View {
    
    @StateObject var viewModel = ListViewModel()
    var resources:[Record]
    var sideMenu = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    Spacer().frame(height: 20)
                    LazyVGrid(columns: viewModel.columns, spacing: 40) {ForEach(resources.sorted(by: {$0.fields.label < $1.fields.label }), id: \.id) { apiData in
                        largeTile(label: apiData.fields.label , imageUrl: apiData.fields.logo?.first?.url ?? "", description: apiData.fields.descriptionNotes ?? "")
                            .accentColor(.primary)
                            .onTapGesture {
                                viewModel.selectedResource = apiData.fields
                                viewModel.isShowingDetail = true
                            }
                    }
                    }
                    .listStyle(.plain)
                }
                .refreshable { viewModel.getResources() }
            }
            
        }
        .overlay {
            if resources.isEmpty && viewModel.isLoading {
                LoadingView()
            } else if resources.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(title: alertItem.title,
                  message: alertItem.message,
                  dismissButton: alertItem.dismissButton)
            
        }
        .sheet(isPresented: $viewModel.isShowingDetail) {
            Spacer().frame(height: 20)
            DetailView(apiData: viewModel.selectedResource ?? MockData.sampleResource)
                .presentationDragIndicator(.visible)
        }
        
    }
    
}

//#Preview {
//    MapTileListView(resources: filteredResources)
//}

