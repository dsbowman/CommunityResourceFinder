//
//  Header.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct Header: View {
    var body: some View {
        VStack(alignment: .center) {
                Image("SmallThings")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
        }
        .padding(.vertical, -25)
    }
}

#Preview {
    Header()
}
