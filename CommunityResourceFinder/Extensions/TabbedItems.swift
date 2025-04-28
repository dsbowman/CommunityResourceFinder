//
//  TabbedItems.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/30/24.
//

import Foundation

enum TabbedItems: Int, CaseIterable {
    case list = 0
    case map
    case settings
//    case migration
//    case profile
    
    
    var title: String {
        switch self {
            
        case .list :
            return "List"
        case .map :
            return "Map"
        case .settings :
            return "Settings"
//        case .profile :
//            return "Profile"
//        case .migration :
//            return "Migration"
        }
    }
    
    var iconName: String {
        switch self {
        case .list:
            return "list.bullet"
        case .map:
            return "map"
        case .settings:
            return "gear"
//        case .profile:
//            return "person.fill"
//        case .migration:
//            return "square.and.arrow.down"
        }
    }
    
    
}


