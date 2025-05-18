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
    
    @ObservedObject var viewModel = ListViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: viewModel.columns, spacing: 30) {ForEach(viewModel.filteredResources.sorted(by: {$0.label < $1.label }), id: \.id) { resource in
                        largeTile(resource: resource)
                            .accentColor(.primary)
                            .onTapGesture {
                                viewModel.activeSheet = .resourceDetail(resource)
                                viewModel.selectedResource = resource
                                
                            }
                    }
                    }
//                    .listStyle(.plain)
                    .navigationTitle("Resources Finder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
//                        ToolbarItem {
//                            Button {
//                                viewModel.newResource = true
//                            } label: {
//                                Image(systemName: "plus.circle.fill")
//                                    .imageScale(.large)
//                                    .fontWeight(.semibold)
//                                    .tint(.softBlue)
//                            }
//                        }
//                        ToolbarItem {
//                            Button {
//                                viewModel.updateAllLocations()
//                                
//                            } label: {
//                                Text("Update Locations")
//                            }
//                        }
                                                
                    }
                    
                    .background(.ultraThinMaterial)
//                    .task {
//                        if viewModel.resources.isEmpty {
//                            viewModel.subscribeToResources()
//                        }
//                    }
                    .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Resources") {
                        
                    }
                    
                    .background(Color("DarkNavy"))
                }
                .refreshable {
                    viewModel.downloadResources()
                }
                
                
            }
            .alert(item: $viewModel.alertItem) { alertItem in
                Alert(title: alertItem.title,
                      message: alertItem.message,
                      dismissButton: alertItem.dismissButton)
                
            }
            .sheet(item: $viewModel.activeSheet) { sheetType in
                Spacer().frame(height: 20)
                switch sheetType {
                case .resourceDetail(let resource):
                    DetailView(resource: resource)
                    
                case .issueForm:
                    WebView(url: URL(string:  "https://airtable.com/appG874fGad8U9K7y/pag8d4CoJAscwVHcY/form")!)

                case .NewResource:
                    WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/paggA8fCAQVTEOrBT/form")!)
    

                case .webView(_):
                    WebView(url: URL(string: "https://www.resourcefinder.app/") ?? URL(string: "https://www.google.com")!)
                }
 
            }
            .presentationDragIndicator(.visible)

        }
    }
}

    #Preview {
        TileView()
    }

