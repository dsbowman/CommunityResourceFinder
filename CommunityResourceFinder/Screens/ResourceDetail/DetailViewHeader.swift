//
//  DetailViewHeader.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 9/19/24.
//

import SwiftUI

struct DetailViewHeader: View {
    
    var headerData: Fields
    
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
                    .background(.white)
                    .cornerRadius(20)
                    
                    HStack {
                        Text(headerData.label)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fontWeight(.semibold)
                        //                            Spacer()
                        //                        Image(systemName: "heart")
                    }
                    .padding(5)
                    
                }
                .frame(width: 350)
            } else {
                VStack(alignment: .center) {
                    Text(headerData.label)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    
                    
                }
            }
        }
    }
}


#Preview {
    DetailViewHeader(headerData: MockData.sampleResource)
}
