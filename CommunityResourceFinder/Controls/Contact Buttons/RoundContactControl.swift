//
//  RoundContactControl.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/3/24.
//

import Foundation
import SwiftUI
import WebKit
import SafariServices


class RoundContactControl {
    
    struct ActionButton: View {

        @State var showWebView = false
        var icon: String
        var activeColor: Color = .darkBlue
        var url: String?
        var loadWebsite: Bool?
        var isDisabled: Bool = false
        
        
        var body: some View {
            
            Button(action: {
                if loadWebsite == true && url != nil {
                    showWebView.toggle()
                } else {
                    if let url = URL(string:url!) {
                        UIApplication.shared.open(url)
                    }
                }
            }) {
                ZStack(alignment: .center) {
                    Circle()
                        .foregroundColor(isDisabled ? .gray : activeColor)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .imageScale(.large)
                }
                .frame(width: 40, height: 40)
                
            }
            .disabled(isDisabled)
            
            .sheet(isPresented: $showWebView, content: {
                WebView(url: URL(string: url!)!)
                    .ignoresSafeArea()
            })
            
        }
    }
}

#Preview {
    RoundContactControl.ActionButton(icon: "person.crop.circle.fill", activeColor: .init(red: 0.1, green: 0.2, blue: 0.3), url: "https://www.apple.com")
}
