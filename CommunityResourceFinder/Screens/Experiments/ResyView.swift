//
//  ResyView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct ResyView: View {
    
    @StateObject var viewModel = ListViewModel()
    
    
    var body: some View {
        
        ZStack {

            Button(action: {
                viewModel.isShowingList = true
            }, label: {
                /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
            })
            

        }
        .sheet(isPresented: $viewModel.isShowingList) {
            ZStack {
                
                VStack {
                    TileSheetView()
                        
                }
                
            }
            
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Resources")
        
    }
}



#Preview {
    ResyView()
}



struct TileSheetView: View {
    
    @StateObject var viewModel = ListViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: viewModel.columns, spacing: 40) {ForEach(viewModel.filteredResources.sorted(by: {$0.fields.label < $1.fields.label }), id: \.id) { apiData in
                    NavigationLink(destination: DetailView(apiData: apiData.fields)) {
                        largeTile(label: apiData.fields.label , imageUrl: apiData.fields.logo?.first?.url ?? "", description: apiData.fields.descriptionNotes ?? "")
                            .accentColor(.primary)
                    }
                    
                }
                }
                .listStyle(.plain)
                .task { viewModel.getResources() }
                .refreshable { viewModel.getResources() }
            }
        }
    }
}
