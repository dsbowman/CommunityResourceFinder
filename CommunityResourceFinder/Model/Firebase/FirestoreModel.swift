//
//  Resource.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/12/24.
//

import Foundation
import FirebaseFirestore
import CoreLocation

//struct Resource: Identifiable, Codable {
//    @DocumentID var id: String?
//    var label: String
//    var description: String?
//    var type: ResourceType
//    var url: String?
//    var logoUrl: String?
//    var tags: [String]?
//    var mainPhone: String?
//    var emergencyPhone: String?
//    var generalEmail: String?
//    var locations: [Location]?
//    var contacts: [Contact]?
//    var status: ResourceStatus
//    
//    enum ResourceType: String, Codable {
//        case organization = "Organization"
//        case program = "Program"
//        case event = "Event"
//    }
//    
//    enum ResourceStatus: String, Codable {
//        case active
//        case inactive
//        case pending
//    }
//    
//    // Location embedded type
//    struct Location: Identifiable, Codable {
//        @DocumentID var id: String?
//        var label: String
//        var street1: String?
//        var street2: String?
//        var city: String?
//        var state: String?
//        var zip: String?
//        var hoursOfOperation: [HoursOfOperation]?
//        var latitude: Double?
//        var longitude: Double?
//        var locationPhone: String?
//        var locationEmail: String?
//    
//        var coordinate: CLLocationCoordinate2D? {
//            if let lat = latitude, let long = longitude {
//                return CLLocationCoordinate2D(latitude: lat, longitude: long)
//            }
//            return nil
//        }
//    }
//    
//    // Contact embedded type
//    struct Contact: Identifiable, Codable {
//        @DocumentID var id: String?
//        var label: String
//        var phone: String?
//        var email: String?
//        var role: String?
//        var locationId: String?
//    }
//    
//    // Hours of operation structure
//    struct HoursOfOperation: Codable {
//        var days: [DayHours]
//        
//        struct DayHours: Identifiable, Codable {
//            var id: String { day.rawValue }
//            var day: Weekday
//            var open: String?
//            var close: String?
//        }
//        
//        enum Weekday: String, Codable, CaseIterable {
//            case monday, tuesday, wednesday, thursday, friday, saturday, sunday
//        }
//    }
//    
//    // Helper computed properties
//    var primaryLocation: Location? {
//        locations?.first
//    }
//    
//    var imagePath: String {
//        "resource_images/\(id ?? "")/logo.jpg"
//    }
//}


struct Resource: Identifiable, Codable {
    @DocumentID var id: String?
    var label: String
    var description: String?
    var type: ResourceType
    var url: String?
    var logoUrl: String?
    var tags: [String]?
    // Organization-level contact information
    var mainPhone: String?
    var emergencyPhone: String?
    var generalEmail: String?
    // Nested structures
    var locations: [Location]?
    var contacts: [Contact]?
    var status: Status
    var airtableId: String?
}

// Nested Resource Types
extension Resource {
    struct Location: Identifiable, Codable {
        @DocumentID var id: String?
        var label: String
        var street1: String?
        var street2: String?
        var city: String?
        var state: String?
        var zip: String?
        var hoursOfOperation: [HoursOfOperation]?
        var latitude: Double?
        var longitude: Double?
        // Location-specific contact info
        var locationPhone: String?
        var locationEmail: String?
        
        var coordinate: CLLocationCoordinate2D? {
            if let lat = latitude, let long = longitude {
                return CLLocationCoordinate2D(latitude: lat, longitude: long)
            }
            return nil
        }
        
    }
    
    
    struct HoursOfOperation: Codable {
        
        enum WeekDay: String, Codable {
            case monday = "Monday"
            case tuesday = "Tuesday"
            case wednesday = "Wednesday"
            case thursday = "Thursday"
            case friday = "Friday"
            case saturday = "Saturday"
            case sunday = "Sunday"
        }
        
        // This represents a single day's hours
        struct DayHours: Codable {
            var day: WeekDay
            var open: String?
            var close: String?
        }
        
        var days: [DayHours]
        
        // Computed property example - gives us easy access to Monday's hours
        var monday: DayHours? {
            // This searches through the days array to find the first entry
            // where the day matches .monday, returning nil if not found
            return days.first { $0.day == .monday }
        }
        
        // This is a helper method to update or add hours for a specific day
        mutating func update(day: WeekDay, open: String?, close: String?) {
            // First, try to find if we already have hours for this day
            if let index = days.firstIndex(where: { $0.day == day }) {
                // If we found existing hours, update them
                days[index].open = open
                days[index].close = close
            } else {
                // If we didn't find hours for this day, add new ones
                days.append(DayHours(day: day, open: open, close: close))
            }
        }
    }
    
    struct Contact: Identifiable, Codable {
        @DocumentID var id: String?
        var label: String          // e.g., "Intake Coordinator", "Program Director"
        var phone: String?
        var email: String?
        var role: String?          // Additional context about the contact's role
        var locationId: String?    // Optional reference to specific location
    }
    
    // Helper computed properties
    var primaryLocation: Location? {
        locations?.first
    }
    
    var imagePath: String {
        "resource_images/\(airtableId ?? "")/logo.jpg"
    }
}




// MARK: - User Domain
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var display_name: String
    var role: String
    var favorites: [String]?
}

// MARK: - Tag Domain
struct Tag: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
}

// MARK: - Review Domain
struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var resource_id: String
    var user_id: String
    var rating: Int
    var comment: String?
    var createdAt: Date
    var updatedAt: Date?
}

enum Status: String, Codable {
    case active
    case inactive
    case pending
}

enum ResourceType: String, Codable {
    case organization = "Organization"
    case program = "Program"
    case event = "Event"
}



