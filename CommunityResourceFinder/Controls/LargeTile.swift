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
                            .padding()
                    
                }
                
            }
        }
        
        

        
    }
}

#Preview {
    largeTile(label: "This is an organizations very long name", imageUrl: "https://v5.airtableusercontent.com/v3/u/24/24/1705384800000/0VQr7VMb5K7ss7csojgVTw/0VFmtIufF3yDWBVrtuS7ICq7o53BeZG2-67DdrtHDFcW2eJq5vLV7XxHGGBPBwCUluruomDXVmqmZFPWeg7kpevaCnjQfV0jCRcJmmaQFy550hgfzBInViB9XMbTgc0DvG9c1_Ipz4DoSyCC7jUMP8pZD54dTccO7lTwdZnxZeUdBSs6lzLeNBSvix0lCgEM/lyCN0ucmEAT0oS7C6swn_QNACv3mz5N_z5buSR5KrWk")
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
