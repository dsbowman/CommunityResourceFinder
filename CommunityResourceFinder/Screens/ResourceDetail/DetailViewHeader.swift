//
//  DetailViewHeader.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/19/24.
//

import SwiftUI

struct DetailViewHeader: View {
    var resource: Resource
//    var headerData: Fields
    @State private var headerHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .center) {
            if let id = resource.id, !id.isEmpty {
                let imagePath = resource.imagePath
                
                VStack() {
                    FirebaseImage(path: imagePath)
                    .padding(20)
                    .frame(width: 350, height: 150)
                    HStack {
                        Text(resource.label)
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fontWeight(.semibold)
                    }
                }
//                .background(.white)
                
            } else {
                VStack(alignment: .center) {
                    Text(resource.label)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    
                    
                }
//                .background(.white)
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
//        .background(.white)
    }
}


//#Preview {
//    DetailViewHeader(headerData: MockData.sampleResource)
//}
