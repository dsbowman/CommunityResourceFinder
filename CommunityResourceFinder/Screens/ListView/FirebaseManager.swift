////
////  FirebaseManager.swift
////  CommunityResourceFinder
////
////  Created by Deke Bowman on 4/29/25.
////
//
//import Foundation
//
//
//@Observable
//class FirebaseManager {
//    
//    var dataLoadState: DataLoadState = .notLoaded
//    var isLoading: Bool = false
//    
////    func loadResources() {
////        if dataLoadState == .failed || dataLoadState == .notLoaded {
////            isLoading = true
////        }
////        
////        switch dataLoadState {
////        case .notLoaded:
////            loadFromServer()
////        case .loadFromCache:
////            <#code#>
////        case .loadFromServer:
////            <#code#>
////        case .failed:
////            <#code#>
////        }
////        
////    }
//    
//    private func loadFromCache() {
//        print("Loading from cache")
//    }
//    
//    private func loadFromServer() {
//        print("Loading from server")
//    }
//    
////    private func loadSubCollections(for document: QueryDocumentSnapshot) async throws -> Resource {
////        
////    }
//    
//    
//}
//
//enum DataLoadState {
//    case notLoaded
//    case loadFromCache
//    case loadFromServer
//    case failed
//}
