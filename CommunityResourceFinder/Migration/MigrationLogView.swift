//
//  MigrationLogView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/31/24.
//

import SwiftUI

struct MigrationLogView: View {
    
    let logs: [MigrationLogEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Migration Log")
                .font(.headline)
                .padding(.bottom, 4)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(logs) { entry in
                        LogEntryRow(entry: entry)
                        
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    // Create some sample log entries to use in the preview
        let sampleLogs = [
            MigrationLogEntry(
                timestamp: Date(),
                message: "Starting migration process",
                type: .info
            ),
            MigrationLogEntry(
                timestamp: Date().addingTimeInterval(-60),
                message: "Successfully migrated user data",
                type: .success
            ),
            MigrationLogEntry(
                timestamp: Date().addingTimeInterval(-120),
                message: "Warning: Some fields were empty",
                type: .warning
            ),
            MigrationLogEntry(
                timestamp: Date().addingTimeInterval(-180),
                message: "Error: Network connection lost",
                type: .error
            )
        ]


    MigrationLogView(logs: sampleLogs)
}

// A separate view for individual log entries helps keep our code organized
struct LogEntryRow: View {
    let entry: MigrationLogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Status indicator dot
            Circle()
                .fill(entry.type.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            // Log message and timestamp
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.message)
                    .foregroundStyle(.primary)
                
                // Format the timestamp to show just the time
                Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }
}
