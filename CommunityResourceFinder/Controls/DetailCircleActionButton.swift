//
//  DetailCircleActionButton.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/11/24.
//

import SwiftUI

struct DetailCircleActionButton: View {
    
    var label: String
    var image: String
    var imageColor: Color
    var action: String?
    var state: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            CircleButton(icon: "phone.fill", action: "812-552-9102")
            
            Button(action: {
                
            }) {
                CircleButtonView(icon: "envelope.fill")
            }
            
            Button(action: {
                
            }) {
                CircleButtonView(icon: "map.fill")
            }
            
            Button(action: {
                
            }) {
                CircleButtonDisabled(icon: "safari.fill")
            }
            
        }
    }
}

#Preview {
    DetailCircleActionButton(label: "Test", image: "phone.fill", imageColor: .primary, action: "812-552-9102", state: false)
}

struct CircleButtonView: View {
    
    var icon: String
    var backgroundColor: Color?
    
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .foregroundColor(backgroundColor ?? .teal)
            Image(systemName: icon)
                .foregroundColor(.white)
                .imageScale(.large)
        }
        .frame(width: 40, height: 40)
    }
}


struct CircleButton: View {
    
    var icon: String
    var backgroundColor: Color?
    var foregroundColor: Color?
    var action: String
    var disabled: Bool?
    
    var body: some View {
        Button(action: {
            if let url = URL(string: action) {
                UIApplication.shared.open(url)
            }
        }) {
            ZStack(alignment: .center) {
                Circle()
                    .foregroundColor(backgroundColor ?? .teal)
                Image(systemName: icon)
                    .foregroundColor(foregroundColor ?? .white)
                    .imageScale(.large)
            }
            .frame(width: 40, height: 40)
            
        }
    }
}

struct CircleButtonDisabled: View {
    
    var icon: String
    var disabled: Bool?
    
    var body: some View {
            ZStack(alignment: .center) {
                Circle()
                    .foregroundColor(.gray)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .imageScale(.large)
            }
            .frame(width: 40, height: 40)
    }
}


