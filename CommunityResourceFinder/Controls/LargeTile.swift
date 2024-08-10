//
//  LargeTile.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

import SwiftUI

struct largeTile: View {
    var label: String = "Organization Name"
    var imageUrl: String?
    var description: String?
    var phone: String?
    
    var body: some View {
        VStack(alignment: .center) {
            if let imageUrl = imageUrl, let _ = URL(string: imageUrl) {
                VStack() {
                    ResourceRemoteImage(urlString: imageUrl)
                        .aspectRatio(contentMode: .fit)
                        .padding(20)
                        .frame(width: 350, height: 150)
                        .background(.white)
                        .cornerRadius(20)
                    
                    HStack {
                        Text(label)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fontWeight(.semibold)
                        Spacer()
//                        Image(systemName: "heart")
                    }
                    .padding(5)
                    
                }
                .frame(width: 350)
                .shadow(radius: 30)

            } else {
                VStack(alignment: .center) {
                        Text(label)
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(20)
                            .frame(width: 350, height: 150)
                            .background(.white)
                            .cornerRadius(20)
                    
                }
                .frame(width: 350)
                .shadow(radius: 30)
                
            }
        }
        
        

        
    }
}

#Preview {
    largeTile(label: "This is an organizations very long name")
}

//struct TextLabel: View {
//    var label:String
//    var body: some View {
//        Text(label)
//            .font(.headline)
//            .fontWeight(.semibold)
//            .lineLimit(2)
//            .multilineTextAlignment(.center)
//            .padding(5)
//            .padding(.bottom, 5)
//    }
//}
