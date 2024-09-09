//
//  APError.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import Foundation

enum RFError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case unableToComplete
}
