//
//  Review.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/12/24.
//

import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var resource_id: String
    var user_id: String
    var rating: Int
    var comment: String
}
