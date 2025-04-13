//
//  ListingsViewModel.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

/// ViewModel responsible for managing Listing data and Firestore interactions
class ListingsViewModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var listings: [Listing] = []
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreListings = true
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let db = Firestore.firestore()
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    private var listener: ListenerRegistration?
    
    init() {
        listenForListings()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Public Methods
    public func fetchListings() {
        resetPaginationState()
        fetchData(query: createBaseQuery(), isInitialFetch: true)
    }
    
    public func loadMoreListings() {
        guard canLoadMore, let lastDoc = lastDocument else { return }
        isLoadingMore = true
        
        let query = db.collection("listings")
            .order(by: "name")
            .start(afterDocument: lastDoc)
            .limit(to: pageSize)
            
        fetchData(query: query, isInitialFetch: false)
    }
    
    func addListing(_ listing: Listing) {
        db.collection("listings").document().setData(
            createListingData(from: listing)
        ) { [weak self] error in
            self?.handleFirestoreError(error, message: "Error adding listing")
        }
    }
    
    func updateListing(_ listing: Listing) {
        guard let id = listing.id else {
            handleFirestoreError(NSError(domain: "", code: -1), message: "Missing listing ID")
            return
        }
        
        db.collection("listings").document(id).updateData(
            createListingData(from: listing)
        ) { [weak self] error in
            self?.handleFirestoreError(error, message: "Error updating listing")
        }
    }
    
    func deleteListing(_ listing: Listing) {
        guard let id = listing.id else {
            handleFirestoreError(NSError(domain: "", code: -1), message: "Missing listing ID")
            return
        }
        
        db.collection("listings").document(id).delete { [weak self] error in
            self?.handleFirestoreError(error, message: "Error deleting listing")
        }
    }
    
    // MARK: - Private Helpers
    private var canLoadMore: Bool {
        !isLoadingMore && hasMoreListings && lastDocument != nil
    }
    
    private func createBaseQuery() -> Query {
        db.collection("listings")
          .order(by: "name")
          .limit(to: pageSize)
    }
    
    private func resetPaginationState() {
        listings = []
        lastDocument = nil
        hasMoreListings = true
    }
    
    private func listenForListings() {
        listener = createBaseQuery().addSnapshotListener { [weak self] snapshot, error in
            self?.processQueryResults(snapshot: snapshot, error: error, isInitialFetch: true)
        }
    }
    
    private func fetchData(query: Query, isInitialFetch: Bool) {
        isLoadingMore = !isInitialFetch
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            defer { self.isLoadingMore = false }
            
            self.processQueryResults(snapshot: snapshot, error: error, isInitialFetch: isInitialFetch)
        }
    }
    
    private func processQueryResults(snapshot: QuerySnapshot?, error: Error?, isInitialFetch: Bool) {
        if let error = error {
            handleFirestoreError(error, message: "Error fetching listings")
            return
        }
        
        guard let documents = snapshot?.documents, !documents.isEmpty else {
            hasMoreListings = false
            if isInitialFetch {
                listings = []
            }
            return
        }
        
        lastDocument = documents.last
        hasMoreListings = documents.count >= pageSize
        
        let newListings = documents.compactMap(createListingFromDocument)
        
        if isInitialFetch {
            listings = newListings
        } else {
            listings.append(contentsOf: newListings)
        }
    }
    
    private func createListingFromDocument(_ document: QueryDocumentSnapshot) -> Listing? {
        let data = document.data()
        return Listing(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            category: data["category"] as? String ?? "",
            description: data["description"] as? String ?? "",
            location: data["location"] as? String ?? "",
            isBrizPick: data["isBrizPick"] as? Bool,
            isVegan: data["isVegan"] as? Bool,
            isVeg: data["isVeg"] as? Bool,
            isDog: data["isDog"] as? Bool,
            isChild: data["isChild"] as? Bool
        )
    }
    
    private func createListingData(from listing: Listing) -> [String: Any] {
        var data: [String: Any] = [
            "name": listing.name,
            "category": listing.category,
            "description": listing.description,
            "location": listing.location
        ]
        
        if let isBrizPick = listing.isBrizPick { data["isBrizPick"] = isBrizPick }
        if let isVegan = listing.isVegan { data["isVegan"] = isVegan }
        if let isVeg = listing.isVeg { data["isVeg"] = isVeg }
        if let isDog = listing.isDog { data["isDog"] = isDog }
        if let isChild = listing.isChild { data["isChild"] = isChild }
        
        return data
    }
    
    private func handleFirestoreError(_ error: Error?, message: String) {
        if let error = error {
            errorMessage = "\(message): \(error.localizedDescription)"
            showError = true
            print("❌ \(message): \(error)")
        }
    }
}
