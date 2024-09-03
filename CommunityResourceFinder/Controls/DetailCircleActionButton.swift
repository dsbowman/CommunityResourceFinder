//
//  DetailCircleActionButton.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/11/24.
//

import SwiftUI

struct DetailCircleActionButton: View {
    
    var phone: String?
    var email: String?
    var street1: String?
    var street2: String?
    var city: String?
    var state: String?
    var url: String?
    
    
    var body: some View {
        HStack(spacing: 30) {
            if let phone = phone {
                CircleButton(icon: "phone.fill", action: "tel:\(phone)")
            } else {
                CircleButtonDisabled(icon: "phone.fill")
            }
            
            if let email = email {
                CircleButton(icon: "envelope.fill", action: "mailto:\(email)")
            } else {
                CircleButtonDisabled(icon: "envelope.fill")
            }
            
            if let street1 = street1, let street2 = street2, let city = city, let state = state {
                CircleButton(icon: "map.fill", action: "http://maps.apple.com/?address=\(street1),\(street2),\(city),\(state)")
            } else {
                CircleButtonDisabled(icon: "map.fill")
            }
            
            if let url = url {
                CircleButton(icon: "safari.fill", action: url)
                
            } else {
                CircleButtonDisabled(icon: "safari.fill")
            }
            
        }
    }
}

#Preview {
    DetailCircleActionButton()
}

struct CircleButton: View {
    
    var icon: String
    var action: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: action) {
                UIApplication.shared.open(url)
            }
        }) {
            ZStack(alignment: .center) {
                Circle()
                    .foregroundColor(.darkBlue)
                Image(systemName: icon)
                    .foregroundColor(.white)
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


