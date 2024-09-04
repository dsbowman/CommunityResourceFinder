//
//  DetailCircleActionButton.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/11/24.
//

import SwiftUI
import WebKit
import SafariServices


struct ContactMenu: View {
    
    var phone: String?
    var emergency: String?
    var email: String?
    var street1: String?
    var street2: String?
    var city: String?
    var state: String?
    var url: String?
    
    
    
    var body: some View {
        HStack(spacing: 25) {
            if let emergency = emergency {
                RoundContactControl.ActionButton(icon: "sos.circle", activeColor: .red, url: "tel:\(emergency)")
            }
            
            if let phone = phone {
                RoundContactControl.ActionButton(icon: "phone.fill", url: "tel:\(phone)")
            } else {
                RoundContactControl.ActionButton(icon: "phone.fill", isDisabled: true)
            }
            
            if let email = email {
                RoundContactControl.ActionButton(icon: "envelope.fill", url: "mailto:\(email)")
            } else {
                RoundContactControl.ActionButton(icon: "envelope.fill", isDisabled: true)
            }
            
            if let street1 = street1, let city = city, let state = state {
                RoundContactControl.ActionButton(icon: "map.fill", url: "http://maps.apple.com/?address=\(street1),\(city),\(state)")
            } else {
                RoundContactControl.ActionButton(icon: "map.fill", isDisabled: true)
            }
            
            if let url = url {
                RoundContactControl.ActionButton(icon: "safari.fill", url: url, loadWebsite: true)
                
            } else {
                RoundContactControl.ActionButton(icon: "safari.fill", isDisabled: true)

            }
            
        }
    }
}

#Preview {
    ContactMenu()
}


