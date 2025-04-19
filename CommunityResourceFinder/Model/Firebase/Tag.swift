//
//  Tag.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/12/24.
//

import Foundation
import FirebaseFirestore

struct Tag: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
}
