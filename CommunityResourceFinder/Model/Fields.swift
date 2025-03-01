//
//  Fields.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/30/24.
//

import Foundation

extension Fields {
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Required field validation
        if label.isEmpty {
            errors.append(.missingRequiredField("label"))
        }
        
        // Phone number validation
        if let phone = phoneContact {
            if !isValidPhoneNumber(phone) {
                errors.append(.invalidPhoneNumber(phone))
            }
        }
        
        // Email validation
        if let email = email {
            if !isValidEmail(email) {
                errors.append(.invalidEmail(email))
            }
        }
        
        // ZIP code validation
        if let zip = zip {
            if !isValidZipCode(zip) {
                errors.append(.invalidZipCode(zip))
            }
        }
        
        // State validation
        if let state = state {
            if !isValidState(state) {
                errors.append(.invalidStateCode(state))
            }
        }
        
        return errors
    }
    
    // Helper validation methods
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        // Remove all non-numeric characters
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Check if we have 10 digits (standard US phone number)
        // or 11 digits (with country code)
        return digits.count == 10 || (digits.count == 11 && digits.hasPrefix("1"))
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Basic email validation using regular expression
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidZipCode(_ zip: String) -> Bool {
        // Basic ZIP code validation (5 digits or 5+4 format)
        let zipRegex = "^\\d{5}(-\\d{4})?$"
        let zipPredicate = NSPredicate(format:"SELF MATCHES %@", zipRegex)
        return zipPredicate.evaluate(with: zip)
    }
    
    private func isValidState(_ state: String) -> Bool {
        // Set of valid US state codes
        let validStates = Set(["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                             "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
                             "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
                             "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                             "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
                             "DC", "PR", "VI", "GU", "MP", "AS"])
        
        return validStates.contains(state.uppercased())
    }
}
