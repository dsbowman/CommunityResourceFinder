//
//  MainTabedView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/30/24.
//

import SwiftUI

struct MainTabbedView: View {
    
    @State var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                TileView()
                    .tag(0)
                //                    .tabItem { Label("List", systemImage: "list.bullet") }
                
                //            ListView()
                //                .tabItem { Label("List", systemImage: "list.bullet") }
                
                MapView()
                    .tag(1)
                //                    .tabItem { Label("Map", systemImage: "globe")}
                
            }
            
            
        }
        .accentColor(.teal)
    }
}


#Preview {
    MainTabbedView()
}

extension MainTabbedView {
    func CustomTabItem(imageName: String, title: String, isActive: Bool) -> some View{
        HStack(spacing: 10){
            Spacer()
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(isActive ? .black : .gray)
                .frame(width: 20, height: 20)
            if isActive{
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .black : .gray)
            }
            Spacer()
        }
        .frame(width: isActive ? .infinity : 60, height: 60)
        .background(isActive ? .purple.opacity(0.4) : .clear)
        .cornerRadius(30)
    }
}
