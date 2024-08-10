//
//  ContentView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            TileView()
                .tabItem { Label("List", systemImage: "list.bullet") }
            
//            ListView()
//                .tabItem { Label("List", systemImage: "list.bullet") }
            
            MapView()
                .tabItem { Label("Map", systemImage: "globe")}
            
            
            
        }
        .accentColor(.teal)
    }
}



#Preview {
    ContentView()
}

