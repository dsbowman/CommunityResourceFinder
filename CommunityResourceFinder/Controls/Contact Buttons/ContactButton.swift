//
//  ContactButton.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct ContactButton: View {
    
    var label: String
    var image: String
    var imageColor: Color
    var action: String
    var state: Bool
    
    var body: some View {
        Button(action: {
            if let url = URL(string: action) {
                UIApplication.shared.open(url)
            }
            
        }) {
            VStack {
                Image(systemName: image)
                    .padding(1)
                    .foregroundColor(imageColor)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(imageColor)
            }
            .frame(width: 50, height: 35)
        }
        .buttonStyle(.bordered)
        .disabled(state)
            
    }
    
}

#Preview {
    ContactButton(label: "Emergency", image: "asterisk", imageColor: .red, action: "tel:812-552-9102", state: false)
}
