//
//  FirestoreManager.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/14/24.
//

import FirebaseFirestore

class FirestoreManager: ObservableObject {
    @Published var resources: [Resource] = []

    private let db = Firestore.firestore()

    func fetchResources() {
        db.collection("resources").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }

            if let snapshot = snapshot {
                self.resources = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Resource.self)
                }
            }
        }
    }
}
