//
//  User 2.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/14/24.
//


import Foundation
import FirebaseFirestore


struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var display_name: String
    var role: String
    var favorites: [String]
}