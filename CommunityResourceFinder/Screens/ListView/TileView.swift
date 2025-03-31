//
//  TileView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
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
                    .task { viewModel.subscribeToResources()}
                    .background(.ultraThinMaterial)
                }
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Resources") {
                    
                }
//                .searchSuggestions{
//                    Text("Food").searchCompletion("Food")
//                    Text("Housing").searchCompletion("Housing")
//                }
                .refreshable { viewModel.subscribeToResources()}
                .background(Color("DarkNavy"))
            }
            
 
        }
//        .onAppear {
//            print("View appeared - resource count: \(viewModel.resources.count)")
//        }
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

        
        
        .sheet(isPresented: $viewModel.newResource) {
//            NewResourceView(newResource: $viewModel.newResource)
            WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/paggA8fCAQVTEOrBT/form")!)
                .presentationDragIndicator(.visible)
        }
//        .onAppear {
//            viewModel.testFirestoreConnection()
//        }
        
    }
    
}

#Preview {
    TileView()
}

