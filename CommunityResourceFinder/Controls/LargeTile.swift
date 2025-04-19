//
//  LargeTile.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct largeTile: View {
    var resource: Resource? = nil
    
    var body: some View {
        VStack(alignment: .center) {
            // When using the new Resource model
            if let resource = resource {
                if let id = resource.airtableId, !id.isEmpty {
                    // We have a resource with an airtableid, so we can try to load the image
                    let imagePath = resource.imagePath
                    
                    VStack {
                        FirebaseImage(path: imagePath)
                            .aspectRatio(contentMode: .fit)
                            .padding(20)
                            .frame(width: 350, height: 150)
                            .background(.white)
                            .cornerRadius(20)
                        
                        HStack {
                            Text(resource.label)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(5)
                    }
                } else {
                    // No ID, so show text alternative
                    VStack(alignment: .center) {
                        Text(resource.label)
                            .font(.title2)
                            .foregroundStyle(.black)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(20)
                            .frame(width: 350, height: 150)
                            .background(.white)
                            .cornerRadius(20)
                    }
                }
            }
        }
        .frame(width: 350)
        .shadow(radius: 30)
    }
}




//#Preview {
//    largeTile(label: "This is an organizations very long name")
//}
