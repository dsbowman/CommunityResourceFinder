//
//  ValidationError.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/30/24.
//

import Foundation

enum ValidationError: Error {
    case invalidPhoneNumber(String)
    case invalidEmail(String)
    case invalidZipCode(String)
    case missingRequiredField(String)
    case invalidStateCode(String)
    
    var description: String {
        switch self {
        case .invalidPhoneNumber(let number):
            return "Invalid phone number format: \(number)"
        case .invalidEmail(let email):
            return "Invalid email format: \(email)"
        case .invalidZipCode(let zip):
            return "Invalid ZIP code format: \(zip)"
        case .missingRequiredField(let field):
            return "Required field missing: \(field)"
        case .invalidStateCode(let state):
            return "Invalid state code: \(state)"
        }
    }
}
