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

        var icon: String
        var url: String?
        var isDisabled: Bool = false
        
        var body: some View {
            Button(action: {
//                if let url = URL(string:url!) {
//                    UIApplication.shared.open(url)
//                }
            }) {
                ZStack(alignment: .center) {
                    Circle()
                        .foregroundColor(isDisabled ? .gray : .darkBlue)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .imageScale(.large)
                }
                .frame(width: 40, height: 40)
                
            }
            .disabled(isDisabled)
        }
    }
    
    
    
    
    
//    struct CallButton: View {
//        
//        var phone: String
//        var isActive: Bool
//        
//        var body: some View {
//            Button(action: {
//                if let url = URL(string: "tel:\(phone)") {
//                    UIApplication.shared.open(url)
//                }
//            }) {
//                ZStack(alignment: .center) {
//                    Circle()
//                        .foregroundColor(isActive ? .darkBlue : .gray)
//                    Image(systemName: "phone.fill")
//                        .foregroundColor(.white)
//                        .imageScale(.large)
//                }
//                .frame(width: 40, height: 40)
//                
//            }
//        }
//    }
//    
//    
//    
//    
//    struct EmailButton: View {
//        
//        var icon: String
//        var action: String
//        
//        var body: some View {
//            Button(action: {
//                if let url = URL(string: action) {
//                    UIApplication.shared.open(url)
//                }
//            }) {
//                ZStack(alignment: .center) {
//                    Circle()
//                        .foregroundColor(.darkBlue.opacity(1))
//                    Image(systemName: "envelope.fill")
//                        .foregroundColor(.white)
//                        .imageScale(.large)
//                }
//                .frame(width: 40, height: 40)
//                
//            }
//        }
//    }
//    
//    struct DirectionsButton: View {
//        
//        var icon: String
//        var action: String
//        
//        var body: some View {
//            Button(action: {
//                if let url = URL(string: action) {
//                    UIApplication.shared.open(url)
//                }
//            }) {
//                ZStack(alignment: .center) {
//                    Circle()
//                        .foregroundColor(.darkBlue.opacity(1))
//                    Image(systemName: icon)
//                        .foregroundColor(.white)
//                        .imageScale(.large)
//                }
//                .frame(width: 40, height: 40)
//                
//            }
//        }
//    }
//    
//    struct URLButton: View {
//        
//        var icon: String
//        var action: String
//        
//        var body: some View {
//            Button(action: {
//                if let url = URL(string: action) {
//                    showWebView.toggle()
//                }
//            }), label: {
//                ZStack(alignment: .center) {
//                    Circle()
//                        .foregroundColor(.darkBlue.opacity(1))
//                    Image(systemName: icon)
//                        .foregroundColor(.white)
//                        .imageScale(.large)
//                }
//                .frame(width: 40, height: 40)
//                .sheet(isPresented: $showWebView, content: {
//                    WebView(url: URL(string: url)!)
//                        .ignoresSafeArea()
//                    
//                })
//                
//            }
//            
//        }
//    }
//    
//    
//    
//    struct CircleButtonDisabled: View {
//        
//        var icon: String
//        var disabled: Bool?
//        
//        var body: some View {
//            ZStack(alignment: .center) {
//                Circle()
//                    .foregroundColor(.gray)
//                Image(systemName: icon)
//                    .foregroundColor(.white)
//                    .imageScale(.large)
//            }
//            .frame(width: 40, height: 40)
//        }
//    }
    
}
