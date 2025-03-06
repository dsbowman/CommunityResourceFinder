//
//  MigrationView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/30/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct MigrationView: View {
    @State private var migrationService = FirestoreMigrationService()
    @StateObject var listViewModel = ListViewModel()
    @StateObject var mapViewModel = MapViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var connectionStatus = "Not tested yet"
    @State private var isLoading = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
//    init() {
//        listViewModel.getResources()
//        mapViewModel.fetchCoordinates()
//    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Migration Status Card
                    statusCard
                    
                    // Migration Logs Section
                    logsSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Data Migration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(migrationService.migrationStatus == "Migration in progress")
                }
            }
            .alert("Migration Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
           
        }
        .task {
            listViewModel.getResources()
            mapViewModel.fetchCoordinates()
        }
        
    }
    
    // Status Card View
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Migration Status")
                .font(.headline)
            
            Text(migrationService.migrationStatus)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading) {
                ProgressView(value: migrationService.migrationProgress) {
                    Text("\(Int(migrationService.migrationProgress * 100))%")
                        .font(.caption)
                }
                
                Text(migrationService.currentOperation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        }
    }
    
    // Logs Section View
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Migration Logs")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(migrationService.migrationLogs, id: \.self) { log in
                        LogEntryView(log: log)
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        }
        
    }
    
    // Action Buttons View
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                showConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Start Migration")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(migrationService.migrationStatus == "Not Started" ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .disabled(migrationService.migrationStatus != "Not Started")
            
            Button(action: testFirebaseConnection) {
                Text("Test Firebase Connection")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .confirmationDialog(
            "Start Data Migration",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start Migration", role: .destructive) {
                startMigrationProcess()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will migrate all of your Airtable data to Firestore. This process cannot be undone. Make sure you have a backup of your data before proceeding.")
        }
    }
    
    // Individual Log Entry View
    private struct LogEntryView: View {
        let log: String
        
        var body: some View {
            HStack(alignment: .top) {
                Text(log)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                Spacer()
            }
            .padding(.horizontal, 8)
            // Add a subtle background for every other log entry
            .background(
                Color(.systemGray6)
                    .opacity(0.5)
                    .cornerRadius(4)
            )
        }
    }
    
    private func startMigrationProcess() {
        let service = migrationService
        
        // Add debug logging at the start
        print("DEBUG: Starting migration process")
        print("DEBUG: Number of resources in ListViewModel: \(listViewModel.resources.count)")
        
        Task {
            do {
                // Add more debug logging
                if listViewModel.resources.isEmpty {
                    print("DEBUG: ⚠️ ListViewModel resources array is empty!")
                } else {
                    print("DEBUG: First resource label: \(listViewModel.resources[0].fields.label)")
                }
                
                try await service.migrateResources(from: listViewModel.resources)
                
                await MainActor.run {
                    if service.migrationProgress == 1.0 {
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func migrateResourceImages() async throws {
        let progressHandler = { (progress: Double) in
            // Update your UI with progress
            print("Image migration progress: \(Int(progress * 100))%")
        }
        
        // Start the migration
        let results = await ImageMigrationService.shared.migrateImages(
            resources: listViewModel.resources,
            progressUpdate: progressHandler
        )
        
        // Update Firestore with the results
        try await ImageMigrationService.shared.updateFirestoreImages(results)
    }
    
    
    // Function to test Firebase connection
    func testFirebaseConnection() {
            isLoading = true
            connectionStatus = "Testing connection..."
            
            // First, check internet connectivity
            guard let url = URL(string: "https://www.google.com") else { return }
            let task = URLSession.shared.dataTask(with: url) { _, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        connectionStatus = "Network error: \(error.localizedDescription)"
                        isLoading = false
                        return
                    }
                    
                    // If network is available, test Firebase
                    let db = Firestore.firestore()
                    db.collection("connection_tests").document().setData([
                        "timestamp": FieldValue.serverTimestamp(),
                        "message": "Test connection",
                        "device": UIDevice.current.name
                    ]) { error in
                        DispatchQueue.main.async {
                            isLoading = false
                            if let error = error {
                                connectionStatus = "Firebase error: \(error.localizedDescription)"
                            } else {
                                connectionStatus = "Successfully connected to Firebase!"
                            }
                        }
                    }
                }
            }
            task.resume()
        }

}

#Preview {
    MigrationView()
}
