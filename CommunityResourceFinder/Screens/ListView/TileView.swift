//
//  TileView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct TileView: View {
    
    @StateObject var viewModel = ListViewModel()
    var sideMenu = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: viewModel.columns, spacing: 40) {ForEach(viewModel.filteredResources.sorted(by: {$0.fields.label < $1.fields.label }), id: \.id) { apiData in
                        largeTile(label: apiData.fields.label , imageUrl: apiData.fields.logo?.first?.url ?? "", description: apiData.fields.descriptionNotes ?? "")
                                .accentColor(.primary)
                                .onTapGesture {
                                    viewModel.selectedResource = apiData.fields
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
                                    .tint(.teal)
                            }
                        }
                    }
                    .task { viewModel.getResources() }
                }
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Resources")
                .refreshable { viewModel.getResources() }
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
            Spacer().frame(height: 20)
            DetailView(apiData: viewModel.selectedResource ?? MockData.sampleResource)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.newResource) {
//            NewResourceView(newResource: $viewModel.newResource)
            WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/paggA8fCAQVTEOrBT/form")!)
                .presentationDragIndicator(.visible)
        }
        
    }
    
}

#Preview {
    TileView()
}

