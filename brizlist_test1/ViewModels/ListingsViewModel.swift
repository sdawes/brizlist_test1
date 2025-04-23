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
    @Published private(set) var featuredListings: [Listing] = []
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreListings = true
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let db = Firestore.firestore()
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    private var listener: ListenerRegistration?
    
    struct FilterOption {
        let field: String      // Firestore field name (e.g., "isBrizPick")
        let displayName: String // UI display name (e.g., "Briz Picks")
    }
    
    // Dictionary to track which filters are active
    @Published var activeFilterValues: [String: Bool] = [:]
    
    // List of available filters (for UI and reference)
    let availableFilters: [FilterOption] = [
        FilterOption(field: "isBrizPick", displayName: "Briz Picks"),
        FilterOption(field: "isSundayLunch", displayName: "Sunday Lunch"),
        FilterOption(field: "isDog", displayName: "Dog Friendly"),
        FilterOption(field: "isFeatured", displayName: "Featured"),
        // Add more filters as needed
    ]
    
    init() {
        // Initialize all filters to false (inactive)
        for filter in availableFilters {
            activeFilterValues[filter.field] = false
        }
        listenForListings()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Public Methods
    // ================================

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
    
    // Helper to check if any filters are active
    var hasActiveFilters: Bool {
        activeFilterValues.values.contains(true)
    }
    
    // MARK: - Private Helpers
    // ================================

    private var canLoadMore: Bool {
        !isLoadingMore && hasMoreListings && lastDocument != nil
    }
    
    private func createBaseQuery() -> Query {
        var query = db.collection("listings").order(by: "name")
        
        // Apply all active filters
        for (field, isActive) in activeFilterValues {
            if isActive {
                query = query.whereField(field, isEqualTo: true)
            }
        }
        
        return query.limit(to: pageSize)
    }
    
    private func resetPaginationState() {
        listings = []
        featuredListings = []
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
                featuredListings = []
            }
            return
        }
        
        lastDocument = documents.last
        hasMoreListings = documents.count >= pageSize
        
        let newListings = documents.compactMap(createListingFromDocument)
        
        let (featured, regular) = separateFeaturedListings(newListings)
        
        if isInitialFetch {
            featuredListings = featured
            listings = regular
        } else {
            featuredListings.append(contentsOf: featured)
            listings.append(contentsOf: regular)
        }
    }
    
    private func createListingFromDocument(_ document: QueryDocumentSnapshot) -> Listing? {
        let data = document.data()
        
        return Listing(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            category: data["category"] as? String ?? "",
            cuisine: data["cuisine"] as? String ?? "",
            description: data["description"] as? String ?? "",
            location: data["location"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            isBrizPick: data["isBrizPick"] as? Bool,
            isVeg: data["isVeg"] as? Bool,
            isDog: data["isDog"] as? Bool,
            isChild: data["isChild"] as? Bool,
            isSundayLunch: data["isSundayLunch"] as? Bool,
            isFeatured: data["isFeatured"] as? Bool
        )
    }
    
    private func handleFirestoreError(_ error: Error?, message: String) {
        if let error = error {
            errorMessage = "\(message): \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func separateFeaturedListings(_ listings: [Listing]) -> (featured: [Listing], regular: [Listing]) {
        var featured: [Listing] = []
        var regular: [Listing] = []
        
        for listing in listings {
            if listing.isFeatured == true {
                featured.append(listing)
            } else {
                regular.append(listing)
            }
        }
        
        return (featured, regular)
    }
}
