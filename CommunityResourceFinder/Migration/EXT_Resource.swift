////
////  EXT_Resource.swift
////  CommunityResourceFinder
////
////  Created by Deke Bowman on 2/8/25.
////
//
//import Foundation
//
//import FirebaseFirestore
//import CoreLocation
//
//extension Resource {
//    
//    // Known valid tags from our system
//    static let validTags: Set<String> = Set([
//            "Menstrual health", "Free Community Legal Assistance", "Electricity",
//            "Farmers Markets", "Prescription costs", "Housing",
//            "Medicare/Medicaid/SSI", "Lyft", "Cell Phones", "Free clothing",
//            "Behavioral Health", "SNAP", "Case Management & General Resources",
//            "Grief & Loss", "Vision", "Power", "Mail Service",
//            "Identification services", "Mental health crisis response team",
//            "Inpatient Rehab", "Harm Reduction", "Public Transit", "Doctors",
//            "EBT", "Outpatient Rehab", "Transportation", "Bike",
//            "Inpatient mental health treatment", "P-EBT", "Legal aid for homeowners",
//            "Personal Care Needs", "Finding Doctors", "Hygiene", "Support Groups",
//            "Intellectual Disabilities", "Free & low cost professional clothing",
//            "Food", "Food Pantries", "Resources for Seniors", "Finding Therapy Options",
//            "Homelessness", "Free & reduced Cost Health Clinics", "City Council",
//            "Community Fridges", "Water", "WIC", "HIV+ Resources", "Furniture",
//            "Rideshare", "Older Adults Meal Services", "Veteran resources", "Gas",
//            "Health", "Diapers and Baby Supplies", "LGBTQIA+ Resources",
//            "Legal Assistance", "Mental health", "AA", "Utilities & taxes",
//            "Free meals", "Tenants' Rights & Legal aid", "AI-Anon",
//            "Substance Use & Addiction", "Shoes", "Other Health Insurance",
//            "Dental", "Job training/development programs", "Immigrant Services",
//            "Domestic Violence & Abuse", "Feminine Products",
//            "Hot & Cold Weather Emergencies", "Medical Bills",
//            "Employment & Finances", "SEPTA", "Suicide & crisis hotline",
//            "Human Trafficking", "Christianity", "Faith", "Spiritual Guidance",
//            "Shelter"
//        ])
//    
//    
//    // Helper struct to define expected data types and validation rules
//    struct ValidationRules {
//        static let requiredFields = ["label", "status"]
//        static let phonePattern = "^\\d{10}$|^\\d{11}$"  // 10 or 11 digits
//        static let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//        static let zipPattern = "^\\d{5}(-\\d{4})?$"     // 5 digit or 5+4
//    }
//    
//    // Transform Airtable Record to Firestore Resource
//    static func fromAirtable(_ record: Record) throws -> Resource {
//        // Validate required fields first
//        try validateRequiredFields(record.fields)
//        
//        // Create the location
//        let location = Location(
//            id: nil,
//            label: "Main Location",
//            street1: record.fields.street1,
//            street2: record.fields.street2,
//            city: record.fields.city,
//            state: record.fields.state,
//            zip: record.fields.zip,
//            hoursOfOperation: parseHoursOfOperation(record.fields.hoursOfOperation),
//            latitude: record.fields.locationCoordinate?.latitude,
//            longitude: record.fields.locationCoordinate?.longitude,
//            locationPhone: formatPhoneNumber(record.fields.phoneContact),
//            locationEmail: record.fields.email
//        )
//        
//        // Create contacts array
//        var contacts: [Contact] = []
//        
//        // Add main contact if phone exists
//        if let mainPhone = record.fields.phoneContact {
//            contacts.append(Contact(
//                id: nil,
//                label: "Primary",
//                phone: formatPhoneNumber(mainPhone),
//                email: record.fields.email,
//                role: "primary",
//                locationId: nil
//            ))
//        }
//        
//        // Add emergency contact if exists
//        if let emergencyPhone = record.fields.emergencyAssistanceNumber {
//            contacts.append(Contact(
//                id: nil,
//                label: "Emergency",
//                phone: formatPhoneNumber(emergencyPhone),
//                email: nil,
//                role: "emergency",
//                locationId: nil
//            ))
//        }
//        
//        // Add secondary contact if exists
//        if let secondaryPhone = record.fields.phoneContact2 {
//            contacts.append(Contact(
//                id: nil,
//                label: "Secondary",
//                phone: formatPhoneNumber(secondaryPhone),
//                email: nil,
//                role: "secondary",
//                locationId: nil
//            ))
//        }
//        
////        let logoURL = record.fields.logo?.first?.url
//        
//        return Resource(
//            id: nil,
//            label: record.fields.label,
//            description: record.fields.descriptionNotes,
//            type: determineResourceType(record.fields),
//            url: record.fields.url,
////            logoUrl: logoURL,
//            tags: record.fields.tags,
//            mainPhone: formatPhoneNumber(record.fields.phoneContact),
//            emergencyPhone: formatPhoneNumber(record.fields.emergencyAssistanceNumber),
//            generalEmail: record.fields.email,
//            locations: [location],
//            contacts: contacts,
//            status: .active
//        )
//    }
//    
//    private static func validateRequiredFields(_ fields: Fields) throws {
//        for field in ValidationRules.requiredFields {
//            switch field {
//            case "label":
//                guard !fields.label.isEmpty else {
//                    throw ValidationError.missingRequiredField("label")
//                }
//            case "status":
//                guard fields.status != nil else {
//                    throw ValidationError.missingRequiredField("status")
//                }
//            default:
//                break
//            }
//        }
//    }
//    
//    private static func determineResourceType(_ fields: Fields) -> ResourceType {
//        // Add your logic to determine resource type
//        // For now, defaulting to organization
//        return .organization
//    }
//    
//    // Tag normalization logic
//    private static func normalizeTags(_ inputTags: [String]?) -> [String] {
//        guard let tags = inputTags else { return [] }
//        
//        // Create a dictionary for common variations
//        let tagVariations: [String: String] = [
//            "mental-health": "Mental health",
//            "mentalhealth": "Mental health",
//            "mental_health": "Mental health",
//            "housing assistance": "Housing",
//            "emergency housing": "Housing",
//            "food assistance": "Food",
//            "food bank": "Food Pantries",
//            // Add more variations as you discover them
//        ]
//        
//        return tags.compactMap { tag -> String? in
//            // Normalize the input tag by trimming whitespace and converting to lowercase
//            let normalizedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
//                                 .lowercased()
//            
//            // Check if this is a known variation
//            if let standardTag = tagVariations[normalizedTag] {
//                return standardTag
//            }
//            
//            // Look for the closest matching valid tag
//            let closestMatch = findClosestMatch(for: normalizedTag, in: validTags)
//            
//            // If we found a close match, use it
//            if let match = closestMatch {
//                return match
//            }
//            
//            // If the exact tag exists in our valid tags (case-insensitive), use the proper casing
//            let exactMatch = validTags.first { $0.lowercased() == normalizedTag }
//            return exactMatch
//        }
//    }
//    
//    // Helper function to find the closest matching valid tag
//    private static func findClosestMatch(for tag: String, in validTags: Set<String>) -> String? {
//        // Convert everything to lowercase for comparison
//        let lowercaseTag = tag.lowercased()
//        _ = validTags.map { $0.lowercased() }
//        
//        // First check for contains relationship
//        if let containsMatch = validTags.first(where: {
//            $0.lowercased().contains(lowercaseTag) || lowercaseTag.contains($0.lowercased())
//        }) {
//            return containsMatch
//        }
//        
//        // Check for words in common
//        let tagWords = Set(lowercaseTag.split(separator: " ").map(String.init))
//        var bestMatch: (tag: String, commonWords: Int) = ("", 0)
//        
//        for validTag in validTags {
//            let validTagWords = Set(validTag.lowercased().split(separator: " ").map(String.init))
//            let commonWords = tagWords.intersection(validTagWords).count
//            
//            if commonWords > bestMatch.commonWords {
//                bestMatch = (validTag, commonWords)
//            }
//        }
//        
//        return bestMatch.commonWords > 0 ? bestMatch.tag : nil
//    }
//    
//    
//    private static func parseHoursOfOperation(_ hoursString: String?) -> [HoursOfOperation] {
//        guard hoursString != nil else { return [] }
//        
//        // Create a default structure
//        let defaultHours = HoursOfOperation(days: [
//            HoursOfOperation.DayHours(day: .monday, open: "9:00", close: "17:00"),
//            HoursOfOperation.DayHours(day: .tuesday, open: "9:00", close: "17:00"),
//            HoursOfOperation.DayHours(day: .wednesday, open: "9:00", close: "17:00"),
//            HoursOfOperation.DayHours(day: .thursday, open: "9:00", close: "17:00"),
//            HoursOfOperation.DayHours(day: .friday, open: "9:00", close: "17:00")
//        ])
//        
//        // TODO: Add parsing logic for actual hours string
//        return [defaultHours]
//    }
//    
//    private static func formatPhoneNumber(_ phone: String?) -> String? {
//        guard let phone = phone else { return nil }
//        let numbers = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//        guard numbers.count >= 10 else { return nil }
//        return numbers
//    }
//}
