//
//  LoadingView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.color = UIColor.lightGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {

    }
    
}

struct LoadingView: View {
    
    var loadingMessage = "Downloading and updating resources..."
    var loadingViewIcon = "Logo"
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                .opacity(0.8)
            
            VStack {
                Image(loadingViewIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                
                Text(loadingMessage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                
                ProgressView()
                    .scaleEffect(1.25)

            }
        }
    }
}

//struct ProgressView: View {
//    var body: some View {
//        ZStack {
//            Color(.systemBackground)
//                .ignoresSafeArea()
//            
//            VStack {
//                ProgressView("Loading")
//                    .progressViewStyle(.linear)
//            }
//        }
//    }
//}

#Preview {
    LoadingView()
}
