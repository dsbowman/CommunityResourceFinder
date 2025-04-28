//
//  ContentView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    
    @State var selectedTab = 0
    @StateObject private var sharedViewModel = ListViewModel()
        
    var body: some View {
        
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TileView(viewModel: sharedViewModel)
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)
                    
                MapView(viewModel: sharedViewModel)
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)
                
                SettingsView()
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)
                
//                MigrationView()
//                    .tag(2)
//                    .toolbar(.hidden, for: .tabBar)
            }
//            .safeAreaInset(edge: .bottom) {
//                TabViewControl()
//            }

            HStack{
                ForEach((TabbedItems.allCases), id: \.self){ item in
                    Button{
                        selectedTab = item.rawValue
                    } label: {
                        CustomTabItem(imageName: item.iconName, title: item.title, isActive: (selectedTab == item.rawValue))
                    }
                }
            }
            .padding(6)
            .frame(height: 60)
            .background(.softBlue)
            .cornerRadius(25)
            .padding(.horizontal, 26)
            .padding(.bottom, 10)

        }
        .accentColor(.teal)
        .task {
            sharedViewModel.subscribeToResources()
        }
        .overlay {
            if sharedViewModel.isLoading {
                LoadingView()
            } else if sharedViewModel.filteredResources.isEmpty {
                ContentUnavailableView.search(text: sharedViewModel.searchText)
            }
        }
        
        
    }
}



#Preview {
    ContentView()
}

extension ContentView {
    func CustomTabItem(imageName: String, title: String, isActive: Bool) -> some View {
        HStack(spacing: 10){
            Spacer()
            Image(systemName: imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(isActive ? .white : .white)
                .frame(width: 20, height: 20)
            if isActive{
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .white : .white)
            }
            Spacer()
        }
        .frame(width: isActive ? 125 : 60, height: 50)
        //change the first value to .infinity when adding additional menu choices or expand appropriate to the number of choices
        
        .background(isActive ? .darkBlue.opacity(0.5) : .clear)
        .cornerRadius(20)
    }
}
