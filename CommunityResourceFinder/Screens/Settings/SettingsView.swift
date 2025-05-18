//
//  SettingsView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 4/28/25.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var viewModel = ListViewModel()
    
    @State private var showWebView = false
    var url = "https://resourcefinder.help"
    var label: String?
    var fontColor: Color?
    
    var body: some View {
        NavigationStack() {
            List{
                Button( action: {
                    showWebView.toggle()
                }, label: {
                    Text("Resource Finder Privacy Policy")
                })
//                Button( action: {
//                    print("List Settings")
//                }, label: {
//                    Text("List Settings")
//                })
//                Button( action: {
//                    print("Login")
//                }, label: {
//                    Text("Login")
//                })
            }
            .navigationTitle(Text("Settings"))
        }
        .sheet(isPresented: $showWebView, content: {
                    WebView(url: URL(string: url)!)                
        })
    }
}

#Preview {
    SettingsView()
}
