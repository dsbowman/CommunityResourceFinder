//
//  CommunityResourceModel.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import Foundation
import SwiftUI
import MapKit

// MARK: - CommunityResourceModel
struct CommunityResourceModel: Decodable  {
    var records: [Record]
}

// MARK: - Record
struct Record: Decodable, Identifiable {
    var id: String
    var createdTime: String?
    var fields: Fields
}

// MARK: - Fields
struct Fields: Decodable {
    var descriptionNotes: String?
    var url: String?
    var imageURL: String?
    var tags: [String]?
    var logo: [Logo]?
    var type: FieldsType?
    var label: String
    var hoursOfOperation, phoneContact, emergencyAssistanceNumber: String?
    var phoneContact2, street1, street2, email, status: String?
    var state, zip, city: String?
    var location: String?
    var locationCoordinate: CLLocationCoordinate2D?

    enum CodingKeys: String, CodingKey {
        case descriptionNotes = "Description / Notes"
        case url = "URL"
        case imageURL = "ImageURL"
        case tags = "Tags"
        case logo = "Logo"
        case type = "Type"
        case label = "Label"
        case hoursOfOperation = "Hours of Operation"
        case phoneContact = "Phone Contact"
        case emergencyAssistanceNumber = "Emergency Assistance Number"
        case phoneContact2 = "Phone Contact 2"
        case street1 = "Street 1"
        case street2 = "Street 2"
        case email = "Email"
        case status = "Status"
        case state = "State"
        case zip = "Zip"
        case city = "City"
    }
}

// MARK: - Logo
struct Logo: Decodable {
    var id: String?
    var width, height: Int?
    var url: String?
    var filename: String?
    var size: Int?
    var type: TypeEnum?
    var thumbnails: Thumbnails?
}

// MARK: - Thumbnails
struct Thumbnails: Decodable {
    var small, large, full: Full?
}

// MARK: - Full
struct Full: Decodable {
    var url: String?
    var width, height: Int?
}


enum TypeEnum: String, Decodable {
    case imageJPEG = "image/jpeg"
    case imagePNG = "image/png"
    case imageSVGXML = "image/svg+xml"
}

enum FieldsType: String, Decodable {
    case organization = "Organization"
    case program = "Program"
}

struct MockData {
    static let sampleResource = Fields(descriptionNotes: "Mock Data for a mock detail", url: "https://dekebowman.smugmug.com", label: "Demo Mock Detail", hoursOfOperation: "Mon-Fri 9 - 5", phoneContact: "812-555-5555", emergencyAssistanceNumber: "756-555-5555", phoneContact2: "215-121-5555", street1: "1826 Moore Street", email: "demo@testemail.com", state: "PA", zip: "19145", city: "Philadelphia")
}
