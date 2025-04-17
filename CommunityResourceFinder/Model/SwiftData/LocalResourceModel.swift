////
////  LocalResourceModel.swift
////  CommunityResourceFinder
////
////  Created by Deke Bowman on 4/12/25.
////
//
//import Foundation
//import SwiftData
//import CoreLocation
//
//// MARK: Enums
//enum LocalResourceType: String, Codable {
//    case organization = "Organization"
//    case program = "Program"
//    case service = "Service"
//}
//
//
//enum LocalStatus: String, Codable {
//    case active
//    case inactive
//    case pending
//}
//
//enum LocalWeekDay: String, Codable {
//    case monday = "Monday"
//    case tuesday = "Tuesday"
//    case wednesday = "Wednesday"
//    case thursday = "Thursday"
//    case friday = "Friday"
//    case saturday = "Saturday"
//    case sunday = "Sunday"
//}
//
//
//
//// MARK: Models
//@Model
//class LocalResource: Identifiable {
//    var id: String?
//    var label: String
//    var resourcedescr: String?
//    var type: ResourceType
//    var url: String?
//    var logoUrl: String?
//    var tags: [String]?
//    
//    // Organization-level contact information
//    var mainPhone: String?
//    var emergencyPhone: String?
//    var generalEmail: String?
//   
//    // Nested structures
//    var locations: [LocalLocation]?
//    var contacts: [LocalContact]?
//    var status: Status
//    var airtableId: String?
//    
//    @Relationship(.cascade) var locations: [LocalLocation]?
//    @Relationship(.cascade) var contacts: [LocalContact]?
//    
//    init(
//        id: String? = nil,
//        label: String,
//        resourcedescr: String? = nil,
//        type: ResourceType,
//        url: String? = nil,
//        logoUrl: String? = nil,
//        tags: [String]? = nil,
//        mainPhone: String? = nil,
//        emergencyPhone: String? = nil,
//        generalEmail: String? = nil,
//        locations: [LocalLocation]? = nil,
//        contacts: [LocalContact]? = nil,
//        status: Status,
//        airtableId: String? = nil
//    )
//    {
//        self.id = id
//        self.label = label
//        self.resourcedescr = resourcedescr
//        self.type = type
//        self.url = url
//        self.logoUrl = logoUrl
//        self.tags = tags
//        self.mainPhone = mainPhone
//        self.emergencyPhone = emergencyPhone
//        self.generalEmail = generalEmail
//        self.locations = locations
//        self.contacts = contacts
//        self.status = status
//        self.airtableId = airtableId
//    }
//}
//
//
//@Model
//class LocalLocation: Identifiable {
//    var id: String?
//    var label: String
//    var street1: String?
//    var street2: String?
//    var city: String?
//    var state: String?
//    var zip: String?
////    var hoursOfOperation: [HoursOfOperation]?
//    var latitude: Double?
//    var longitude: Double?
//  
//    // Location-specific contact info
//    var locationPhone: String?
//    var locationEmail: String?
//    
//    @Relationship(.cascade, inverse: \LocalResource.locations) var resource: LocalResource?
//    @Relationship(.cascade) var hoursOfOperation: [LocalHoursOfOperation]?
//    
//    init(
//        id: String? = nil,
//        label: String,
//        street1: String? = nil,
//        street2: String? = nil,
//        city: String? = nil,
//        state: String? = nil,
//        zip: String? = nil,
//        latitude: Double? = nil,
//        longitude: Double? = nil,
//        locationPhone: String? = nil,
//        locationEmail: String? = nil
//    )
//    {
//        self.id = id
//        self.label = label
//        self.street1 = street1
//        self.street2 = street2
//        self.city = city
//        self.state = state
//        self.zip = zip
//        self.latitude = latitude
//        self.longitude = longitude
//        self.locationPhone = locationPhone
//        self.locationEmail = locationEmail
//    }
//}
//
//
//@Model
//class LocalHoursOfOperation: Identifiable {
//    var dayString: String
//    var open: String?
//    var close: String?
////    var location: String?
//    
//    var day: LocalWeekDay {
//        get { LocalWeekDay(rawValue: dayString) ?? .monday}
//        set { dayString = newValue.rawValue }
//    }
//    
//    init(
//        day: LocalWeekDay,
//        open: String? = nil,
//        close: String? = nil,
////        location: LocalLocation? = nil
//    ) {
//        self.dayString = day.rawValue
//        self.open = open
//        self.close = close
////        self.location = location
//    }
//    
//}
//
//
//@Model
//class LocalContact: Identifiable {
//    var id: String?
//    var label: String          // e.g., "Intake Coordinator", "Program Director"
//    var phone: String?
//    var email: String?
//    var role: String?          // Additional context about the contact's role
//    var locationId: String?
//    
//    init(
//        id: String? = nil,
//        label: String,
//        phone: String? = nil,
//        email: String? = nil,
//        role: String? = nil,
//        locationId: String? = nil
//    )
//    {
//        self.id = id
//        self.label = label
//        self.phone = phone
//        self.email = email
//        self.role = role
//        self.locationId = locationId
//    }
//    
//}
