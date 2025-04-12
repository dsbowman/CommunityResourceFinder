//
//  MigrationLogEntry.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/31/24.
//

import Foundation
import SwiftUI

// This structure defines what information we want to track for each log entry
struct MigrationLogEntry: Identifiable {
    let id = UUID()               // Unique identifier for each log entry
    let timestamp: Date           // When the log entry was created
    let message: String           // The actual log message
    let type: LogType            // The kind of log entry it is
    
    // LogType helps us categorize and visually distinguish different kinds of logs
    enum LogType {
        case info      // For general information
        case success   // For completed operations
        case error     // For things that went wrong
        case warning   // For potential issues
        
        // Each log type gets its own color for visual distinction
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            }
        }
    }
}
