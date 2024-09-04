//
//  WebView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/4/24.
//

import SwiftUI
import WebKit
import SafariServices

struct WebView: UIViewControllerRepresentable {
    
    var url: URL
  
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<WebView>) -> SFSafariViewController {
            SFSafariViewController(url: url)
        }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<WebView>) {}
}
