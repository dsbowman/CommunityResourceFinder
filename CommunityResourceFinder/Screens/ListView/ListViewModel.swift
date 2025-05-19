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
import FirebasePerformance

@MainActor class ListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var resources: [Resource] = []
    @Published var alertItem: AlertItem?
    @Published var isLoading = false
    @Published var searchText: String = ""
    @Published var activeSheet: SheetType?
    @Published var selectedResource: Resource?
    @Published var mapRegion: MKCoordinateRegion? = nil
    @Published var isLoadingMore = false
    private var lastDocumentSnapshot: DocumentSnapshot?
    @Published var initialBatchSize: Int = 15
    @Published var additionalBatchSize: Int = 30
    private var hasLoadedFromCache = false
    private let initialLoadCompleteKey = "isInitialUploadComplete"
    
    private var isInitialLoadComplete: Bool {
        get {
            UserDefaults.standard.bool(forKey: initialLoadCompleteKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: initialLoadCompleteKey)
        }
    }
    
    
    
    
    // MARK: - Private Properties
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 350))]
    
    
    // MARK: - Computed Properties
    var activeResources: [Resource] {
        resources
    }
    
    var filteredResources: [Resource] {
        guard !searchText.isEmpty else { return activeResources }
        
        return activeResources.filter { resource in
            resource.label.localizedCaseInsensitiveContains(searchText) ||
            resource.description?.localizedCaseInsensitiveContains(searchText) ?? false ||
            resource.tags?.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    //TODO: I need to add logic to account for if the app is expecting cached data but there isn't any or the data has gone stale.
    
    func loadResources() {
        print("Initial Load Check: \(isInitialLoadComplete)")
        if !isInitialLoadComplete {
            downloadResources()
            print("Loading from server")
            
        } else {
            loadResourcesFromCache()
            print("Loading from cache")
        }
    }
    
    
    func downloadResources() {
        print("Starting to load from server")
        self.isLoading = true
        
        let initialQuery = db.collection("resources")
            .whereField("status", isEqualTo: "active")
            .order(by: "label")
            .limit(to: initialBatchSize)
        
        initialQuery.getDocuments(source: .default) { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error downloading initial resources: \(error.localizedDescription)")
                self.alertItem = AlertContext.invalidData
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No resources found")
                return
            }
            
            //Save last document for pagination
            self.lastDocumentSnapshot = documents.last
            
            //Process Resource Documents
            Task {
                do {
                    let resourcesWithSubCollections = try await self.processResourceDocuments(documents)
                    
                    //Update the resources object
                    self.resources = resourcesWithSubCollections
                    self.calculateMapRegion()
                    self.isInitialLoadComplete = true
                    print("set isInitialLoadComplete to true")
                    self.isLoading = false
                    
                    // Start silently loading remaining data
                    if documents.count >= self.initialBatchSize {
                        self.continuePaginationInBackground()
                    }
                } catch {
                    print("Error processing resource documents: \(error.localizedDescription)")
                    self.alertItem = AlertContext.invalidData
                }
            }
            
        }
        
    }
    
    private func processResourceDocuments(_ documents: [QueryDocumentSnapshot]) async throws -> [Resource] {
        var resources: [Resource] = []
        
        for document in documents {
            
            do {
                
                //decode firestore data into resources
                var resource = try document.data(as: Resource.self)
                
                //Load locations for resources
                resource.locations = try await loadLocationsForResources(document)
                
                //Load contacts for resources
                resource.contacts = try await loadContactsForResources(document)
                
                resources.append(resource)
            } catch {
                print("Error processing resource \(document.documentID): \(error)")
            }
        }
        
        return resources
        
    }
    
    private func loadLocationsForResources(_ document: QueryDocumentSnapshot) async throws -> [Resource.Location] {
        let locationsSnapshot = try await document.reference.collection("locations").getDocuments()
        return try locationsSnapshot.documents.compactMap { locationDoc in
            try locationDoc.data(as: Resource.Location.self)
            
        }
        
    }
    
    private func loadContactsForResources(_ document: QueryDocumentSnapshot) async throws -> [Resource.Contact] {
        let contactsSnapshot = try await document.reference.collection("contacts").getDocuments()
        return try contactsSnapshot.documents.compactMap { contactDoc in
            try contactDoc.data(as: Resource.Contact.self)
        }
    }
    
    
    private func continuePaginationInBackground() {
        Task {
            do {
                var hasMoreData = true
                var batchCount = 0
                let maxBackgroundBatches = 5
                
                while hasMoreData && batchCount < maxBackgroundBatches && !Task.isCancelled {
                    let moreResources = try await loadNextbatch()
                    
                    if moreResources.isEmpty {
                        hasMoreData = false
                    } else {
                        await MainActor.run {
                            self.resources.append(contentsOf: moreResources)
                            self.calculateMapRegion()
                        }
                        
                        batchCount += 1
                    }
                    
                    
                }
            } catch {
                print("Background pagination error: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func loadNextbatch() async throws -> [Resource] {
        guard let lastDoc = lastDocumentSnapshot else { return [] }
        
        let isFetchingNextBatch = true
        defer {_ = isFetchingNextBatch}
        
        let nextQuery = db.collection("resources")
            .whereField(("status"), isEqualTo: "active")
            .order(by: "label")
            .start(afterDocument: lastDoc)
            .limit(to: additionalBatchSize)
        
        let snapshot = try await nextQuery.getDocuments()
        
        self.lastDocumentSnapshot = snapshot.documents.last
        
        if snapshot.documents.isEmpty {
            return []
        }
        
        return try await processResourceDocuments(snapshot.documents)
        
    }
    
    
    //MARK: Load Resources from Cache
    
    func loadResourcesFromCache() {
        
        let initialQuery = db.collection("resources")
            .whereField("status", isEqualTo: "active")
            .order(by: "label")
        
        initialQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error downloading initial resources: \(error.localizedDescription)")
                self.alertItem = AlertContext.invalidData
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No resources found")
                return
            }
            
            
            //Process Resource Documents
            Task {
                do {
                    let resourcesWithSubCollections = try await self.processResourceDocumentsFromCache(documents)
                    
                    //Update the resources object
                    self.resources = resourcesWithSubCollections
                    self.calculateMapRegion()
                    self.isInitialLoadComplete = true
                    self.isLoading = false
                    
                    // Start silently loading remaining data
                    if documents.count >= self.initialBatchSize {
                        self.continuePaginationInBackground()
                    }
                } catch {
                    print("Error processing resource documents: \(error.localizedDescription)")
                    self.alertItem = AlertContext.invalidData
                }
            }
            
        }
        
    }
    
    private func processResourceDocumentsFromCache(_ documents: [QueryDocumentSnapshot]) async throws -> [Resource] {
        var resources: [Resource] = []
        
        for document in documents {
            
            do {
                
                //decode firestore data into resources
                var resource = try document.data(as: Resource.self)
                
                //Load locations for resources
                resource.locations = try await loadLocationsForResourcesFromCache(document)
                
                //Load contacts for resources
                resource.contacts = try await loadContactsForResourcesFromCache(document)
                
                resources.append(resource)
            } catch {
                print("Error processing resource \(document.documentID): \(error)")
            }
        }
        
        return resources
        
    }
    
    private func loadLocationsForResourcesFromCache(_ document: QueryDocumentSnapshot) async throws -> [Resource.Location] {
        let locationsSnapshot = try await document.reference.collection("locations").getDocuments(source: .cache)
        return try locationsSnapshot.documents.compactMap { locationDoc in
            try locationDoc.data(as: Resource.Location.self)
            
        }
        
    }
    
    private func loadContactsForResourcesFromCache(_ document: QueryDocumentSnapshot) async throws -> [Resource.Contact] {
        let contactsSnapshot = try await document.reference.collection("contacts").getDocuments(source: .cache)
        return try contactsSnapshot.documents.compactMap { contactDoc in
            try contactDoc.data(as: Resource.Contact.self)
        }
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
    
    //MARK: Process Image for sharelink
    
    func getImageforShareLink(path: ) -> UIImage {
        
    }
    
    
    // MARK: - Update Location
    
    func updateLocation(resourceID: String, lat: Double, lon: Double) {
        print("Updating \(resourceID) to lat: \(lat), lon: \(lon)")
        let resourceRef = db.collection("resources").document(resourceID)
        resourceRef.updateData([
            "primaryLocationLat" : lat,
            "primaryLocationLon" : lon
        ])
    }
    
    func updateAllLocations() {
        for resource in resources {
            if let location = resource.primaryLocation,
               let coordinate = location.coordinate {
                updateLocation(resourceID: resource.id!, lat: coordinate.latitude, lon: coordinate.longitude)
                
            }
            
        }
        
    }
    
}


enum SheetType: Identifiable {
    case resourceDetail(Resource)
    case NewResource
    case issueForm
    case webView(URL)
    
    var id: String {
        switch self {
        case .resourceDetail(let resource):
            return "detail-\(resource.id ?? UUID().uuidString)"
        case .NewResource:
            return "NewResource"
        case .issueForm:
            return "issueForm"
        case .webView(let url):
            return "web-\(url.absoluteString)"
        }
    }
    
}



// MARK: OLD STUFF

//        func subscribeToResourcesWithCache() {
//            print("subscribeToResourcesWithCache is being called")
//
//            let mainTrace = Performance.startTrace(name: "resources_loading_complete")
//            if resources.isEmpty {
//                isLoading = true
//            }
//
//            listener?.remove()
//
//            let cacheTrace = Performance.startTrace(name: "resources_cache_loading")
//
//            let initialQuery = db.collection("resources")
//                .whereField(("status"), isEqualTo: "active")
//                .order(by: "label")
//
//            initialQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
//                guard let self = self else {
//                    cacheTrace?.stop()
//                    mainTrace?.stop()
//                    return
//                }
//
//                cacheTrace?.incrementMetric("cache_document_count", by: Int64(snapshot?.documents.count ?? 0))
//
//                if let snapshot = snapshot, !snapshot.isEmpty {
//                    let processCacheTrace = Performance.startTrace(name: "resources_process_cache")
//
//                    Task {
//                        do {
//                            let cacheProcessStartTime = Date()
//                            let cachedResources = try await self.loadResourcesWithSubcollectionsFromCache(from: snapshot.documents)
//
//                            let processingTime = Date().timeIntervalSince(cacheProcessStartTime)
//                            processCacheTrace?.incrementMetric("cache_processing_time_ms", by: Int64(processingTime * 1000))
//                            processCacheTrace?.incrementMetric("cache_processing_time", by: Int64(cachedResources.count))
//
//                            if !cachedResources.isEmpty {
//                                self.resources = cachedResources
//                                self.isLoading = false
//                            }
//                            self.hasLoadedFromCache = true
//
//                            //Stop the cache processing trace
//                            processCacheTrace?.stop()
//                        } catch {
//                            print("Error loading from cache: \(error)")
//                            processCacheTrace?.incrementMetric("cache_processing_errors", by: 1)
//                            processCacheTrace?.stop()
//                        }
//                    }
//                }
//
//                //Stop cache loading trace
//                cacheTrace?.stop()
//
//                self.setupListener(for: initialQuery)
//
//            }
//
//        }
//
//
//
//
//        // MARK: - Public Methods
//        func subscribeToResources() {
//            print("subscribeToResources is being called")
//
//            // Create trace for entire function
//            let mainTrace = Performance.startTrace(name: "resources_loading_complete")
//            // Don't show full loading if we've already loaded from cache
//            if resources.isEmpty {
//                isLoading = true
//            }
//
//            // Remove any existing listener
//            listener?.remove()
//
//
//            // Trace for cache loading
//            let cacheTrace = Performance.startTrace(name: "resources_cache_loading")
//
//            // First try to load from cache
//            let initialQuery = db.collection("resources")
//                .whereField("status", isEqualTo: "active")
//                .order(by: "label")
//                .limit(to: initialBatchSize) // Add getdocument() here at the top includes:
//
//
//            // Try to load from cache first
//            initialQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
//                guard let self = self else {
//                    cacheTrace?.stop()
//                    mainTrace?.stop()
//                    return
//                }
//
//                print("Cache callback executed: isEmpty: \(snapshot?.isEmpty ?? true), error: \(String(describing: error))")
//
//                // Add metrics to cache trace
//                cacheTrace?.incrementMetric("cache_document_count", by: Int64(snapshot?.documents.count ?? 0))
//
//                if let snapshot = snapshot, !snapshot.isEmpty {
//
//                    let processCacheTrace = Performance.startTrace(name: "resources_process_cache")
//
//                    // Process cached documents
//                    Task {
//                        do {
//                            let cacheProcessStartTime = Date()
//                            let cachedResources = try await self.loadResourcesWithSubcollections(from: snapshot.documents)
//
//                            //Record metrics about the processing time
//                            let processingTime = Date().timeIntervalSince(cacheProcessStartTime)
//                            processCacheTrace?.incrementMetric("cache_processing_time_ms", by: Int64(processingTime * 1000))
//                            processCacheTrace?.incrementMetric("cache_resources_count", by: Int64(cachedResources.count))
//
//
//                            if !cachedResources.isEmpty {
//                                self.resources = cachedResources
//                                self.isLoading = false
//                            }
//                            self.hasLoadedFromCache = true
//                            self.isInitialLoadComplete = true
//                            self.calculateMapRegion()
//
//                            // Stop the cache processing trace
//                            processCacheTrace?.stop()
//
//
//                        } catch {
//                            print("Error loading from cache: \(error)")
//                            processCacheTrace?.incrementMetric("cache_processing_errors", by: 1)
//                            processCacheTrace?.stop()
//                        }
//                    }
//                }
//
//                // Stop cache loading trace
//                cacheTrace?.stop()
//
//                print("Cache snapshot docs count: \(snapshot?.documents.count ?? 0)")
//
//                // Set up listener for the initial batch
//                self.setupListener(for: initialQuery)
//            }
//        }
//
//        private func setupListener(for query: Query) {
//
//            //Trace for listener setup and server loading
//            let listenerTrace = Performance.startTrace(name: "resources_listener_setup")
//
//            //Setup listener for the initial batch
//            listener = query.addSnapshotListener { [weak self] snapshot, error in
//                guard let self = self else {
//                    listenerTrace?.stop()
//                    return
//                }
//
//                if let error = error {
//                    self.handleFirestoreError(error)
//                    listenerTrace?.incrementMetric("listener_errors", by: 1)
//                    listenerTrace?.stop()
//                    return
//                }
//
//                if let error = error {
//                    if self.resources.isEmpty {
//                        self.alertItem = AlertContext.invalidData
//                    } else {
//                        print("Firestore update error (using cashed data): \(error.localizedDescription)")
//                    }
//                    return
//                }
//
//
//                guard let documents = snapshot?.documents else {
//                    if self.resources.isEmpty {
//                        self.alertItem = AlertContext.invalidData
//                    }
//                    listenerTrace?.incrementMetric("empty_document_sets", by: 1)
//                    listenerTrace?.stop()
//
//                    return
//                }
//
//
//                //Record metrics about the documents
//                listenerTrace?.incrementMetric("server_document_count", by: Int64(documents.count))
//
//
//                // Save last document for pagination
//                self.lastDocumentSnapshot = documents.last
//
//                //Trace for processing server documents
//                //            let processServerTrace = Performance.startTrace(name: "resources_process_server")
//
//                // Load resources with subcollections
//                //            Task {
//                //                do {
//                //                    let serverProcessStartTime = Date()
//                //                    let initialResources = try await self.loadResourcesWithSubcollections(from: documents)
//                //
//                //                    //Record metrics about the processing time
//                //                    let processingTime = Date().timeIntervalSince(serverProcessStartTime)
//                //                    processServerTrace?.incrementMetric("server_processing_time_ms", by: Int64(processingTime * 1000))
//                //                    processServerTrace?.incrementMetric("server_resources_count", by: Int64(initialResources.count))
//                //
//                //
//                //                    // Update the UI with initial resources
//                //                    self.resources = initialResources
//                //                    self.calculateMapRegion()
//                //                    self.isLoading = false
//                //                    self.isInitialLoadComplete = true
//                //                    print(String(self.isInitialLoadComplete))
//                //
//                //                    //Stop the server processing trace
//                //                    processServerTrace?.stop()
//                //
//                //
//                //                    // Load more resources in the background after a short delay
//                //                    if documents.count >= self.initialBatchSize {
//                //                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
//                //
//                //                        _ = Performance.startTrace(name: "resources_load_more")
//                //                        self.loadMoreResources()
//                //                    }
//                //                    self.initialLoadComplete = true
//                //                    listenerTrace?.stop()
//                //
//                //                } catch {
//                //                    self.handleFirestoreError(error)
//                //                    processServerTrace?.incrementMetric("server_processing_errors", by: 1)
//                //                    processServerTrace?.stop()
//                //                    listenerTrace?.stop()
//                //                }
//                //            }
//
//            }
//        }
//
//        func loadMoreResources() {
//            guard !isLoadingMore, let lastDoc = lastDocumentSnapshot else { return }
//
//            //        isLoadingMore = true
//
//            let nextQuery = db.collection("resources")
//                .whereField("status", isEqualTo: "active")
//                .order(by: "label")
//                .limit(to: additionalBatchSize)
//                .start(afterDocument: lastDoc)
//
//            // Load the next batch
//            Task {
//                do {
//                    let additionalDocs = try await nextQuery.getDocuments()
//                    if additionalDocs.documents.isEmpty {
//                        isLoadingMore = false
//                        return
//                    }
//
//                    // Update last document reference
//                    lastDocumentSnapshot = additionalDocs.documents.last
//
//                    // Load resources with subcollections
//                    let additionalResources = try await self.loadResourcesWithSubcollections(from: additionalDocs.documents)
//
//                    // Append to existing resources
//                    self.resources.append(contentsOf: additionalResources)
//                    self.calculateMapRegion()
//                    self.isLoadingMore = false
//
//                    // Continue loading more resources if there are more available
//                    if additionalDocs.documents.count >= self.additionalBatchSize {
//                        self.loadMoreResources()
//                    }
//                } catch {
//                    self.isLoadingMore = false
//                    print("Error loading more resources: \(error.localizedDescription)")
//                }
//            }
//        }
//
//        func testFirestoreConnection() {
//            Task {
//                do {
//                    let snapshot = try await db.collection("resources").limit(to: 1).getDocuments()
//                    print("Successfully connected to Firestore. Found \(snapshot.documents.count) resources.")
//                } catch {
//                    print("Failed to connect to Firestore: \(error.localizedDescription)")
//                    self.alertItem = AlertContext.unableToComplete
//                }
//            }
//        }
//
//        // MARK: - Private Methods
//
//
//        private func loadResourcesWithSubcollections(from documents: [QueryDocumentSnapshot]) async throws -> [Resource] {
//            if initialLoadComplete {
//                print("💾 loading from Cache")
//                return try await loadResourcesWithSubcollectionsFromCache(from: documents)
//            } else {
//                print("🛜 loading from server")
//                return try await loadResourcesWithSubcollectionsFromServer(from: documents)
//            }
//        }
//
//
//        private func loadResourcesWithSubcollectionsFromServer(from documents: [QueryDocumentSnapshot]) async throws -> [Resource] {
//            let subcollectionTrace = Performance.startTrace(name: "load_resource_subcollections_from_server")
//            subcollectionTrace?.incrementMetric("document_count", by: Int64(documents.count))
//
//            var resources: [Resource] = []
//            var locationLoadCount = 0
//            var contactLoadCount = 0
//
//            for document in documents {
//                do {
//
//                    // Decode the main resource document
//                    let decodeStartTime = Date()
//                    var resource = try document.data(as: Resource.self)
//                    let decodeTime = Date().timeIntervalSince(decodeStartTime)
//                    subcollectionTrace?.incrementMetric("document_decode_time_ms", by: Int64(decodeTime * 1000))
//
//
//                    // Load locations subcollection
//                    let locationStartTime = Date()
//                    let locationsSnapshot = try await document.reference.collection("locations").getDocuments()
//                    let locationDocuments = locationsSnapshot.documents
//                    locationLoadCount += locationDocuments.count
//
//                    resource.locations = try locationsSnapshot.documents.compactMap { locationDoc in
//                        try locationDoc.data(as: Resource.Location.self)
//                    }
//                    let locationTime = Date().timeIntervalSince(locationStartTime)
//                    subcollectionTrace?.incrementMetric("locations_load_time_ms", by: Int64(locationTime))
//
//
//                    // Load contacts subcollection
//                    let contactStartTime = Date()
//                    let contactsSnapshot = try await document.reference.collection("contacts").getDocuments()
//                    let contactDocuments = contactsSnapshot.documents
//                    contactLoadCount += contactDocuments.count
//
//                    resource.contacts = try contactsSnapshot.documents.compactMap { contactDoc in
//                        try contactDoc.data(as: Resource.Contact.self)
//                    }
//                    let contactTime = Date().timeIntervalSince(contactStartTime)
//                    subcollectionTrace?.incrementMetric("contacts_load_time_ms", by: Int64(contactTime))
//
//                    resources.append(resource)
//                } catch {
//                    print("Error loading resource \(document.documentID): \(error.localizedDescription)")
//                    subcollectionTrace?.incrementMetric("document_errors", by: 1)
//                    // Continue with other resources
//                }
//            }
//
//            //Record overall metrics
//            subcollectionTrace?.incrementMetric("Total_location_documents", by: Int64(locationLoadCount))
//            subcollectionTrace?.incrementMetric("total_contact_documents", by: Int64(contactLoadCount))
//            subcollectionTrace?.incrementMetric("resources_processed", by: Int64(resources.count))
//
//
//            //Stop trace
//            subcollectionTrace?.stop()
//
//            return resources
//        }
//
//        private func loadResourcesWithSubcollectionsFromCache(from documents: [QueryDocumentSnapshot]) async throws -> [Resource] {
//            let subcollectionTrace = Performance.startTrace(name: "load_resource_subcollections_from_cache")
//            subcollectionTrace?.incrementMetric("document_count", by: Int64(documents.count))
//
//            var resources: [Resource] = []
//            var locationLoadCount = 0
//            var contactLoadCount = 0
//
//            for document in documents {
//                do {
//
//                    // Decode the main resource document
//                    let decodeStartTime = Date()
//                    var resource = try document.data(as: Resource.self)
//                    let decodeTime = Date().timeIntervalSince(decodeStartTime)
//                    subcollectionTrace?.incrementMetric("document_decode_time_ms", by: Int64(decodeTime * 1000))
//
//
//                    // Load locations subcollection
//                    let locationStartTime = Date()
//                    let locationsSnapshot = try await document.reference.collection("locations").getDocuments(source: .cache)
//                    let locationDocuments = locationsSnapshot.documents
//                    locationLoadCount += locationDocuments.count
//
//                    resource.locations = try locationsSnapshot.documents.compactMap { locationDoc in
//                        try locationDoc.data(as: Resource.Location.self)
//                    }
//                    let locationTime = Date().timeIntervalSince(locationStartTime)
//                    subcollectionTrace?.incrementMetric("locations_load_time_ms", by: Int64(locationTime))
//
//
//                    // Load contacts subcollection
//                    let contactStartTime = Date()
//                    let contactsSnapshot = try await document.reference.collection("contacts").getDocuments(source: .cache)
//                    let contactDocuments = contactsSnapshot.documents
//                    contactLoadCount += contactDocuments.count
//
//                    resource.contacts = try contactsSnapshot.documents.compactMap { contactDoc in
//                        try contactDoc.data(as: Resource.Contact.self)
//                    }
//                    let contactTime = Date().timeIntervalSince(contactStartTime)
//                    subcollectionTrace?.incrementMetric("contacts_load_time_ms", by: Int64(contactTime))
//
//                    resources.append(resource)
//                } catch {
//                    print("Error loading resource \(document.documentID): \(error.localizedDescription)")
//                    subcollectionTrace?.incrementMetric("document_errors", by: 1)
//                    // Continue with other resources
//                }
//            }
//
//            //Record overall metrics
//            subcollectionTrace?.incrementMetric("Total_location_documents", by: Int64(locationLoadCount))
//            subcollectionTrace?.incrementMetric("total_contact_documents", by: Int64(contactLoadCount))
//            subcollectionTrace?.incrementMetric("resources_processed", by: Int64(resources.count))
//
//
//            //Stop trace
//            subcollectionTrace?.stop()
//
//            return resources
//        }

//    private func saveResourcesLocally(_ resources: [Resource]) {
//        if let encoded = try? JSONEncoder().encode(resources) {
//            UserDefaults.standard.set(encoded, forKey: "cachedResources")
//        }
//    }
//
//    private func loadResourcesLocally() -> [Resource]? {
//        if let data = UserDefaults.standard.data(forKey: "cachedResources"),
//           let resources = try? JSONDecoder().decode([Resource].self, from: data) {
//            return resources
//        }
//        return nil
//    }
