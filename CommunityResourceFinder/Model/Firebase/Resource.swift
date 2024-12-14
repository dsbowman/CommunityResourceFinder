//
//  Resource.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/12/24.
//

import Foundation
import FirebaseFirestore

struct Resource: Identifiable, Codable {
    @DocumentID var id: String?
    var label: String
    var type: String
    var tags: [String]
    var locations: [Location]?
    var contacts: [Contact]?
}

struct Location: Identifiable, Codable {
    @DocumentID var id: String?
    var label: String
    var city: String
    var latitude: Double
    var longitude: Double
}

struct Contact: Identifiable, Codable {
    @DocumentID var id: String?
    var label: String
    var phone: String
}
