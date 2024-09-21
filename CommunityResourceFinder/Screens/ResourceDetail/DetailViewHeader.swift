//
//  DetailViewHeader.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/19/24.
//

import SwiftUI

struct DetailViewHeader: View {
    
    var headerData: Fields
    @State private var headerHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .center) {
            if let imageUrl = headerData.logo?.first?.url, let _ = URL(string: imageUrl) {
                VStack() {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                            .controlSize(.large)
                    }
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
                    .frame(width: 350, height: 150)
                    HStack {
                        Text(headerData.label)
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fontWeight(.semibold)
                    }
                }
                .background(.white)
                
            } else {
                VStack(alignment: .center) {
                    Text(headerData.label)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    
                    
                }
                .background(.white)
            }
            ContactMenu(phone: headerData.phoneContact, emergency: headerData.emergencyAssistanceNumber, email: headerData.email, street1: headerData.street1, street2: headerData.street2, city: headerData.city, state: headerData.state, url: headerData.url)
        }
        .containerRelativeFrame(.horizontal)
        .background(.white)
    }
}


#Preview {
    DetailViewHeader(headerData: MockData.sampleResource)
}
