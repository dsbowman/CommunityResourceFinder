//
//  ListViewModel.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//


import SwiftUI
import MapKit
import CoreLocation
import FirebaseFirestore

@MainActor class ListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var resources: [Resource] = []
    @Published var alertItem: AlertItem?
    @Published var isLoading = true
    @Published var searchText: String = ""
    @Published var isShowingList = true
    @Published var isShowingDetail = false
    @Published var selectedResource: Resource?
    @Published var newResource = false
    @Published var isSheetPresented = true
    @Published var mapRegion: MKCoordinateRegion? = nil
    @Published var showMapView: Bool = false
    @Published var isLoadingMore = false
    private var lastDocumentSnapshot: DocumentSnapshot?
    private let initialBatchSize = 20
    private let additionalBatchSize = 50
    @Published var isInitialLoadComplete = false
    private var hasLoadedFromCache = false
    
 
    // MARK: - Private Properties
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 350))]
    
    // MARK: - Computed Properties
    var activeResources: [Resource] {
        resources.filter { $0.status == .active }
    }
    
    var filteredResources: [Resource] {
        guard !searchText.isEmpty else { return activeResources }
        
        return activeResources.filter { resource in
            resource.label.localizedCaseInsensitiveContains(searchText) ||
            resource.description?.localizedCaseInsensitiveContains(searchText) ?? false ||
            resource.tags?.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    // MARK: - Initialization
    init() {
        // Any initialization logic here
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Public Methods
    func subscribeToResources() {
        // Don't show full loading if we've already loaded from cache
        if !hasLoadedFromCache {
            isLoading = true
        }
        
        // Remove any existing listener
        listener?.remove()
        
        // First try to load from cache
        let initialQuery = db.collection("resources")
            .whereField("status", isEqualTo: "active")
            .order(by: "label")
            .limit(to: initialBatchSize)
        
        // Try to load from cache first
        initialQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                // Process cached documents
                Task {
                    do {
                        self.resources = try await self.loadResourcesWithSubcollections(from: snapshot.documents)
                        self.hasLoadedFromCache = true
                        self.isLoading = false
                        self.isInitialLoadComplete = true
                        self.calculateMapRegion()
                    } catch {
                        print("Error loading from cache: \(error)")
                    }
                }
            }
            
            // Set up listener for the initial batch
            self.setupListener(for: initialQuery)
        }
    }
    
    private func setupListener(for query: Query) {
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleFirestoreError(error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.alertItem = AlertContext.invalidData
                self.isLoading = false
                return
            }
            
            // Save last document for pagination
            self.lastDocumentSnapshot = documents.last
            
            // Load resources with subcollections
            Task {
                do {
                    let initialResources = try await self.loadResourcesWithSubcollections(from: documents)
                    
                    // Update the UI with initial resources
                    self.resources = initialResources
                    self.calculateMapRegion()
                    self.isLoading = false
                    self.isInitialLoadComplete = true
                    
                    // Load more resources in the background after a short delay
                    if documents.count >= self.initialBatchSize {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                        self.loadMoreResources()
                    }
                } catch {
                    self.handleFirestoreError(error)
                }
            }
        }
    }

    func loadMoreResources() {
        guard !isLoadingMore, let lastDoc = lastDocumentSnapshot else { return }
        
        isLoadingMore = true
        
        let nextQuery = db.collection("resources")
            .whereField("status", isEqualTo: "active")
            .order(by: "label")
            .limit(to: additionalBatchSize)
            .start(afterDocument: lastDoc)
        
        // Load the next batch
        Task {
            do {
                let additionalDocs = try await nextQuery.getDocuments()
                if additionalDocs.documents.isEmpty {
                    isLoadingMore = false
                    return
                }
                
                // Update last document reference
                lastDocumentSnapshot = additionalDocs.documents.last
                
                // Load resources with subcollections
                let additionalResources = try await self.loadResourcesWithSubcollections(from: additionalDocs.documents)
                
                // Append to existing resources
                self.resources.append(contentsOf: additionalResources)
                self.calculateMapRegion()
                self.isLoadingMore = false
                
                // Continue loading more resources if there are more available
                if additionalDocs.documents.count >= self.additionalBatchSize {
                    self.loadMoreResources()
                }
            } catch {
                self.isLoadingMore = false
                print("Error loading more resources: \(error.localizedDescription)")
            }
        }
    }
    
    
    
//    func subscribeToResources() {
//        isLoading = true
//        
//        // Remove any existing listener
//        listener?.remove()
//        
//        // Query for active resources ordered by label
//        let query = db.collection("resources")
//            .whereField("status", isEqualTo: "active")
//            .order(by: "label")
//
//        listener = query.addSnapshotListener { [weak self] snapshot, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                self.handleFirestoreError(error)
//                return
//            }
//            
//            guard let documents = snapshot?.documents else {
//                self.alertItem = AlertContext.invalidData
//                self.isLoading = false
//                return
//            }
//            
//            // Use a task group to load all resources with their subcollections
//            Task {
//                do {
//                    self.resources = try await self.loadResourcesWithSubcollections(from: documents)
//                    self.calculateMapRegion()
//                    self.isLoading = false
//                } catch {
//                    self.handleFirestoreError(error)
//                }
//            }
//        }
//    }
    
    func testFirestoreConnection() {
        Task {
            do {
                let snapshot = try await db.collection("resources").limit(to: 1).getDocuments()
                print("Successfully connected to Firestore. Found \(snapshot.documents.count) resources.")
            } catch {
                print("Failed to connect to Firestore: \(error.localizedDescription)")
                self.alertItem = AlertContext.unableToComplete
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadResourcesWithSubcollections(from documents: [QueryDocumentSnapshot]) async throws -> [Resource] {
        var resources: [Resource] = []
        
        for document in documents {
            do {
                // Decode the main resource document
                var resource = try document.data(as: Resource.self)
                
                // Load locations subcollection
                let locationsSnapshot = try await document.reference.collection("locations").getDocuments()
                resource.locations = try locationsSnapshot.documents.compactMap { locationDoc in
                    try locationDoc.data(as: Resource.Location.self)
                }
                
                // Load contacts subcollection
                let contactsSnapshot = try await document.reference.collection("contacts").getDocuments()
                resource.contacts = try contactsSnapshot.documents.compactMap { contactDoc in
                    try contactDoc.data(as: Resource.Contact.self)
                }
                
                resources.append(resource)
            } catch {
                print("Error loading resource \(document.documentID): \(error.localizedDescription)")
                // Continue with other resources
            }
        }
        
        return resources
    }
    
    private func calculateMapRegion() {
        // Skip if no resources with coordinates
        let resourcesWithCoordinates = resources.compactMap { resource -> CLLocationCoordinate2D? in
            if let location = resource.primaryLocation, let coordinate = location.coordinate {
                return coordinate
            }
            return nil
        }
        
        guard !resourcesWithCoordinates.isEmpty else { return }
        
        // Calculate bounds
        var minLatitude = 90.0
        var maxLatitude = -90.0
        var minLongitude = 180.0
        var maxLongitude = -180.0
        
        for coordinate in resourcesWithCoordinates {
            minLatitude = min(minLatitude, coordinate.latitude)
            maxLatitude = max(maxLatitude, coordinate.latitude)
            minLongitude = min(minLongitude, coordinate.longitude)
            maxLongitude = max(maxLongitude, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLatitude - minLatitude) * 1.2,
            longitudeDelta: (maxLongitude - minLongitude) * 1.2
        )
        
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
    
    private func handleFirestoreError(_ error: Error) {
        print("Firestore error: \(error.localizedDescription)")
        
        if let firestoreError = error as NSError?, firestoreError.domain == FirestoreErrorDomain {
            switch firestoreError.code {
            case FirestoreErrorCode.unavailable.rawValue:
                alertItem = AlertContext.unableToComplete
            case FirestoreErrorCode.permissionDenied.rawValue:
                // Handle permission issues
                print("Permission denied: \(firestoreError.localizedDescription)")
                alertItem = AlertContext.unableToComplete
            default:
                alertItem = AlertContext.invalidData
            }
        } else {
            alertItem = AlertContext.invalidResponse
        }
        
        isLoading = false
    }
}





//import SwiftUI
//import MapKit
//import CoreLocation
//import FirebaseFirestore
//
//@MainActor class ListViewModel: ObservableObject {
//    
//    @Published var resources: [Record] = []
//    @Published var alertItem: AlertItem?
//    @Published var isLoading = true
//    @Published var searchText: String = ""
//    @Published var isShowingList = true
//    @Published var isShowingDetail = false
//    @Published var selectedResource: Fields?
//    @Published var newResource = false
//    @Published var isSheetPresented = true
//    @Published var mapRegion: MKCoordinateRegion? = nil // Make it optional
//    private let locationManager = CLLocationManager() // Add location manager
//    private var currentOffset: String? = nil
//    private var hasMoreData = true
//    private var isFetchingData = false // Prevent multiple concurrent fetches
//    let columns: [GridItem] = [GridItem(.adaptive(minimum: 350))]
//    private var lastDocument: QueryDocumentSnapshot?
//    private var isLoadingMoreDocuments = false
//    private let batchSize = 20
//    private var hasMoreDocuments = true
//    private var listener: ListenerRegistration?
//    private let db = Firestore.firestore()
//    
//    
//    var approvedResources: [Record] {
//        resources.filter { $0.fields.status == "Active"}
//    }
//    
//    var filteredResources: [Record] {
//        guard !searchText.isEmpty else {return approvedResources}
//        
//        return approvedResources.filter { resource in
//            resource.fields.label.localizedCaseInsensitiveContains(searchText) || resource.fields.descriptionNotes?.localizedCaseInsensitiveContains(searchText) ?? false || resource.fields.tags?.debugDescription.localizedCaseInsensitiveContains(searchText) ?? false
//        }
//    }
//    
//    func subscribeToResources() {
//        // Clear existing data when starting a fresh subscription
//        listener?.remove()
//        resources = []
//        lastDocument = nil
//        hasMoreDocuments = true
//        
//        isLoading = true
//        print("Starting Firestore subscription...")
//        
//        // Load the first batch
//        loadNextBatch()
//    }
//    
//    private func loadNextBatch() {
//        guard !isLoadingMoreDocuments && hasMoreDocuments else {
//            print("Skip loading: already loading or no more documents")
//            return
//        }
//        
//        isLoadingMoreDocuments = true
//        print("Loading next batch of documents...")
//        
//        // Create base query
//        var query = db.collection("resources")
//            .whereField("status", isEqualTo: "active")
//            .order(by: "label")
//            .limit(to: batchSize)
//        
//        // Add startAfter if we have a lastDocument (not for first batch)
//        if let lastDocument = lastDocument {
//            query = query.start(afterDocument: lastDocument)
//            print("Starting after document: \(lastDocument.documentID)")
//        }
//        
//        // Execute the query
//        query.getDocuments { [weak self] snapshot, error in
//            guard let self = self else { return }
//            
//            defer {
//                self.isLoadingMoreDocuments = false
//            }
//            
//            if let error = error {
//                print("❌ Firestore error: \(error.localizedDescription)")
//                self.handleFirestoreError(error)
//                return
//            }
//            
//            guard let documents = snapshot?.documents, !documents.isEmpty else {
//                // No more documents to load
//                self.hasMoreDocuments = false
//                self.isLoading = false
//                print("✅ No more documents available")
//                return
//            }
//            
//            print("📊 Batch documents count: \(documents.count)")
//            
//            // Update last document for pagination
//            self.lastDocument = documents.last
//            
//            // Process this batch
//            self.processDocumentBatch(documents)
//            
//            // Check if there might be more documents
//            self.hasMoreDocuments = documents.count >= self.batchSize
//        }
//    }
//    
//    private func processDocumentBatch(_ documents: [QueryDocumentSnapshot]) {
//        print("Processing batch of \(documents.count) documents")
//        var loadedResources: [Record] = []
//        
//        for (index, document) in documents.enumerated() {
//            print("Processing document \(index + 1) of \(documents.count): \(document.documentID)")
//            let data = document.data()
//            
//            guard let label = data["label"] as? String, !label.isEmpty else {
//                print("Missing required field 'label' for document \(document.documentID)")
//                continue
//            }
//            
//            // Process this document as before
//            let fields = Fields(
//                descriptionNotes: data["description"] as? String,
//                url: data["url"] as? String,
//                tags: data["tags"] as? [String],
//                logo: self.convertFirestoreLogoToAirtableFormat(data["logoUrl"] as? String),
//                label: label,
//                hoursOfOperation: nil,
//                phoneContact: data["mainPhone"] as? String,
//                emergencyAssistanceNumber: data["emergencyPhone"] as? String,
//                street1: nil,
//                street2: nil,
//                email: data["generalEmail"] as? String,
//                status: "Active",
//                state: nil,
//                zip: nil,
//                city: nil
//            )
//            
//            loadedResources.append(Record(id: document.documentID, fields: fields))
//            print("Successfully processed document: \(document.documentID)")
//        }
//        
//        print("Completed processing batch, adding \(loadedResources.count) resources")
//        
//        // Update the resources array on the main thread
//        DispatchQueue.main.async {
//            // Append to existing resources instead of replacing
//            self.resources.append(contentsOf: loadedResources)
//            print("Total resources count now: \(self.resources.count)")
//            
//            // Load location data for just this batch
//            self.fetchLocationDataForResources(loadedResources)
//            
//            // Load next batch if more are available
//            if self.hasMoreDocuments {
//                print("Loading next batch...")
//                self.loadNextBatch()
//            } else {
//                print("✅ All batches loaded")
//                self.isLoading = false
//            }
//        }
//    }
//    
//    
//    private func fetchLocationDataForResources(_ batchResources: [Record]) {
//        let dispatchGroup = DispatchGroup()
//        
//        for resource in batchResources {
//            guard let index = self.resources.firstIndex(where: { $0.id == resource.id }) else {
//                continue
//            }
//            
//            dispatchGroup.enter()
//            
//            let locationsRef = db.collection("resources").document(resource.id).collection("locations").limit(to: 1)
//            locationsRef.getDocuments { [weak self] snapshot, error in
//                defer { dispatchGroup.leave() }
//                guard let self = self,
//                      let snapshot = snapshot,
//                      !snapshot.documents.isEmpty else { return }
//                
//                let locationDoc = snapshot.documents[0]
//                let data = locationDoc.data()
//                
//                DispatchQueue.main.async {
//                    if index < self.resources.count {
//                        var updatedFields = self.resources[index].fields
//                        updatedFields.street1 = data["street1"] as? String
//                        updatedFields.street2 = data["street2"] as? String
//                        updatedFields.city = data["city"] as? String
//                        updatedFields.state = data["state"] as? String
//                        updatedFields.zip = data["zip"] as? String
//                        
//                        self.resources[index].fields = updatedFields
//                        
//                        // Geocode after updating location if needed
//                        self.geocodeAddressForResource(at: index)
//                    }
//                }
//            }
//        }
//        
//        dispatchGroup.notify(queue: .main) {
//            self.isLoading = false
//        }
//    }
//    
//    private func geocodeAddressForResource(at index: Int) {
//        guard index < resources.count,
//              let street1 = resources[index].fields.street1,
//              let city = resources[index].fields.city,
//              let state = resources[index].fields.state else {
//            return
//        }
//        
//        let address = "\(street1), \(resources[index].fields.street2 ?? ""), \(city), \(state), \(resources[index].fields.zip ?? "")"
//        
//        CLGeocoder().geocodeAddressString(address) { [weak self] placemarks, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                print("Geocoding error for \(address): \(error.localizedDescription)")
//                return
//            }
//            
//            if let placemark = placemarks?.first,
//               let location = placemark.location {
//                
//                DispatchQueue.main.async {
//                    if index < self.resources.count {
//                        self.resources[index].fields.locationCoordinate = location.coordinate
//                        self.calculateRegion()
//                    }
//                }
//            }
//        }
//    }
//    
//    private func formatHoursString(from hoursData: [String: Any]) -> String {
//        var formattedHours = ""
//        let daysOfWeek = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
//        
//        for day in daysOfWeek {
//            if let dayData = hoursData[day] as? [String: String],
//               let open = dayData["open"],
//               let close = dayData["close"],
//               !open.isEmpty && !close.isEmpty {
//                let capitalizedDay = day.prefix(1).uppercased() + day.dropFirst()
//                formattedHours += "\(capitalizedDay): \(open) - \(close)\n"
//            }
//        }
//        
//        return formattedHours.trimmingCharacters(in: .whitespacesAndNewlines)
//    }
//    
//    
//    private func convertFirestoreLogoToAirtableFormat(_ logoUrl: String?) -> [Logo]? {
//        guard let logoUrl = logoUrl, !logoUrl.isEmpty else {
//            print("Logo URL is nil or empty")
//            return nil
//        }
//        
//        // Validate the URL format
//        guard let url = URL(string: logoUrl), UIApplication.shared.canOpenURL(url) else {
//            print("⚠️ Invalid logo URL format: \(logoUrl)")
//            // Try to fix common URL issues
//            if let fixedUrl = fixUrlFormat(logoUrl) {
//                print("Fixed URL to: \(fixedUrl)")
//                return [Logo(id: UUID().uuidString, url: fixedUrl, filename: "logo.jpg")]
//            }
//            return nil
//        }
//        
//        print("✅ Valid logo URL: \(logoUrl)")
//        return [Logo(id: UUID().uuidString, url: logoUrl, filename: "logo.jpg")]
//    }
//    
//    // Helper to fix common URL format issues
//    private func fixUrlFormat(_ urlString: String) -> String? {
//        // Replace spaces with %20
//        var fixed = urlString.replacingOccurrences(of: " ", with: "%20")
//        
//        // Add https if missing
//        if !fixed.lowercased().starts(with: "http") {
//            fixed = "https://" + fixed
//        }
//        
//        // Validate the fixed URL
//        if URL(string: fixed) != nil {
//            return fixed
//        }
//        
//        return nil
//    }
//    
//    
//    
//    
//    private func handleFirestoreError(_ error: Error) {
//        print("Firestore error: \(error.localizedDescription)")
//        alertItem = AlertContext.unableToComplete
//        isLoading = false
//    }
//    
//    // Clean up listener when view model is deallocated
//    deinit {
//        listener?.remove()
//    }
//    
//    
//    func testFirestoreConnection() {
//        let db = Firestore.firestore()
//        
//        db.collection("resources").getDocuments { (snapshot, error) in
//            if let error = error {
//                print("Error fetching test data: \(error)")
//                
//            } else if let snapshot = snapshot {
//                for document in snapshot.documents {
//                    print("Test Record ID: \(document.documentID), Data: \(document.data())")
//                }
//            }
//            
//        }
//    }
//    
////    func getResources() {
////        guard !isFetchingData && hasMoreData else { return }
////        
////        isLoading = true
////        isFetchingData = true
////        
////        Task {
////            do {
////                let (newResources, nextOffset) = try await NetworkManager.shared.getData(offset: currentOffset)
////                
////                resources.append(contentsOf: newResources)
////                currentOffset = nextOffset
////                hasMoreData = nextOffset != nil
////                
////                fetchCoordinates(for: newResources)
////                
////            } catch {
////                handleNetworkError(error)
////            }
////            isLoading = false  // Done loading
////            isFetchingData = false
////        }
////        
////    }
//    
//    
//    private func handleNetworkError(_ error: Error) {
//        if let RFError = error as? RFError {
//            switch RFError {
//                
//            case .invalidURL:
//                alertItem = AlertContext.invalidURL
//            case .invalidResponse:
//                alertItem = AlertContext.invalidResponse
//            case .invalidData:
//                alertItem = AlertContext.invalidData
//            case .unableToComplete:
//                alertItem = AlertContext.unableToComplete
//            }
//            
//        } else {
//            alertItem = AlertContext.invalidResponse
//        }
//        isLoading = false
//    }
//    
//    func checkConnectivity(completion: @escaping (Bool) -> Void) {
//        guard let url = URL(string: "https://www.google.com") else {
//            completion(false)
//            return
//        }
//        
//        let task = URLSession.shared.dataTask(with: url) { _, response, error in
//            if let error = error {
//                print("Connectivity check failed: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//                return
//            }
//            
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//                DispatchQueue.main.async {
//                    completion(true)
//                }
//            } else {
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//            }
//        }
//        task.resume()
//    }
//    
//    
//    
//    func fetchCoordinates(for newResources: [Record]) {
//        for i in 0..<newResources.count {
//            let record = newResources[i]
//            if let street1 = record.fields.street1, let city = record.fields.city, let state = record.fields.state {
//                
//                let address = "\(street1), \(record.fields.street2 ?? ""), \(city), \(state), \(record.fields.zip ?? "")"
//                
//                CLGeocoder().geocodeAddressString(address) { (placemarks, error) in
//                    if let error = error {
//                        print("Geocoding error for \(address): \(error.localizedDescription)")
//                        return
//                    }
//                    
//                    if let placemark = placemarks?.first,
//                       let location = placemark.location {
//                        
//                        DispatchQueue.main.async { // Update on main thread
//                            self.resources[i].fields.locationCoordinate = location.coordinate
//                            self.calculateRegion()
//                        }
//                    } else {
//                        print("No coordinates found for \(address)")
//                    }
//                }
//            }
//            
//            //            DispatchQueue.main.async {
//            //                self.calculateRegion()
//            //                self.isLoading = false  // Done loading
//            //            }
//            
//        }
//        
//    }
//    
//    func calculateRegion() {
//        var minLatitude = 90.0
//        var maxLatitude = -90.0
//        var minLongitude = 180.0
//        var maxLongitude = -180.0
//        
//        for record in resources {
//            if let coordinate = record.fields.locationCoordinate {
//                minLatitude = min(minLatitude, coordinate.latitude)
//                maxLatitude = max(maxLatitude, coordinate.latitude)
//                minLongitude = min(minLongitude, coordinate.longitude)
//                maxLongitude = max(maxLongitude, coordinate.longitude)
//                
//            }
//        }
//        
//        let center = CLLocationCoordinate2D(
//            latitude: (minLatitude + maxLatitude) / 2,
//            longitude: (minLongitude + maxLongitude) / 2
//        )
//        
//        let span = MKCoordinateSpan(
//            latitudeDelta: (maxLatitude - minLatitude) * 1.2, // Add padding
//            longitudeDelta: (maxLongitude - minLongitude) * 1.2 // Add padding
//        )
//        
//        mapRegion = MKCoordinateRegion(center: center, span: span)
//    }
//    
//    
//    
//    
//    
//}
