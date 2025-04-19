//
//  DetailViewHeader.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/19/24.
//

import SwiftUI

struct DetailViewHeader: View {
    var resource: Resource
    @State private var headerHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .center) {
            if let id = resource.id, !id.isEmpty {
                let imagePath = resource.imagePath
                
                VStack(spacing: 20) {
                    FirebaseImage(path: imagePath)
                        .id(resource.id)
                        .padding(.horizontal ,20)
                    .frame(width: 350, height: 150)
                    Text(resource.label)
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 5)
                }
                
            } else {
                VStack(alignment: .center) {
                    Text(resource.label)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    
                }
            }
            
            if let location = resource.primaryLocation {
                ContactMenu(
                    phone: resource.mainPhone,
                    emergency: resource.emergencyPhone,
                    email: resource.generalEmail,
                    street1: location.street1,
                    street2: location.street2,
                    city: location.city,
                    state: location.state,
                    url: resource.url)
            } else {
                ContactMenu(
                    phone: resource.mainPhone,
                    emergency: resource.emergencyPhone,
                    email: resource.generalEmail,
                    url: resource.url)
                
            }
        }
        .containerRelativeFrame(.horizontal)
    }
}


//#Preview {
//    DetailViewHeader(headerData: MockData.sampleResource)
//}
