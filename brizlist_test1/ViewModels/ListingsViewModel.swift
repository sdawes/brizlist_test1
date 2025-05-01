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
    @Published var selectedTags: Set<String> = []
    @Published var noResultsFromFiltering: Bool = false
    
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
    
    // Add this helper property to check if tag filtering is active
    var hasTagFilters: Bool {
        return !selectedTags.isEmpty
    }
    
    // MARK: - Private Helpers
    // ================================

    private var canLoadMore: Bool {
        !isLoadingMore && hasMoreListings && lastDocument != nil
    }
    
    private func createBaseQuery() -> Query {
        // Start with CollectionReference and then convert to Query
        let collectionRef = db.collection("listings")
        var query: Query = collectionRef.order(by: "name")
        
        // Filter by tags if any are selected
        if !selectedTags.isEmpty {
            // For "AND" tag filtering, we need to check that each document contains all selected tags
            // We'll use multiple array-contains queries in combination with filter client-side
            
            // Start with the first tag (we need at least one in the Firestore query)
            let tagsArray = Array(selectedTags)
            query = query.whereField("typeFilters", arrayContains: tagsArray[0])
            
            // We'll need to filter the rest of the tags client-side in processQueryResults
        }
        
        // Apply all other active filters (your existing code)
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
        
        // Check if we have any filters active 
        let hasActiveFilters = self.hasActiveFilters || self.hasTagFilters
        
        guard let documents = snapshot?.documents else {
            hasMoreListings = false
            if isInitialFetch {
                listings = []
                featuredListings = []
                
                // Set the noResultsFromFiltering flag if we have filters but no results
                noResultsFromFiltering = hasActiveFilters
            }
            return
        }
        
        // Additional client-side filtering if we have multiple tags
        // (Firestore can only query for one array-contains at a time)
        var filteredDocuments = documents
        if selectedTags.count > 1 {
            let allTags = Array(selectedTags)
            // Skip the first tag as it was already filtered in the query
            let additionalTags = allTags.dropFirst()
            
            // Filter documents to contain ALL the selected tags (AND operation)
            filteredDocuments = documents.filter { document in
                guard let documentTags = document.data()["typeFilters"] as? [String] else {
                    return false
                }
                
                // Check that all additional tags are present in the document
                for tag in additionalTags {
                    if !documentTags.contains(tag) {
                        return false
                    }
                }
                return true
            }
        }
        
        // Check if we have results after client-side filtering
        if filteredDocuments.isEmpty {
            hasMoreListings = false
            if isInitialFetch {
                listings = []
                featuredListings = []
                
                // Set the noResultsFromFiltering flag
                noResultsFromFiltering = hasActiveFilters
            }
            return
        }
        
        // Found results, so reset the no results flag
        noResultsFromFiltering = false
        
        lastDocument = documents.last // Keep the original last document for pagination
        hasMoreListings = documents.count >= pageSize
        
        let newListings = filteredDocuments.compactMap(createListingFromDocument)
        
        // We still use separateFeaturedListings for reference, but we'll include all listings in the main array
        let (featured, regular) = separateFeaturedListings(newListings)
        
        if isInitialFetch {
            featuredListings = featured
            listings = newListings  // Use all listings, not just regular
        } else {
            featuredListings.append(contentsOf: featured)
            listings.append(contentsOf: newListings)  // Use all listings, not just regular
        }
    }
    
    private func createListingFromDocument(_ document: QueryDocumentSnapshot) -> Listing? {
        let data = document.data()
        
        return Listing(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            typeFilters: data["typeFilters"] as? [String] ?? [],
            cuisine: data["cuisine"] as? String ?? "",
            shortDescription: data["shortDescription"] as? String ?? "",
            location: data["location"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            isBrizPick: data["isBrizPick"] as? Bool,
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
            if listing.isFeatured ?? false {
                featured.append(listing)
            } else {
                regular.append(listing)
            }
        }
        
        return (featured, regular)
    }
    
    // Add these methods to manage tag selection
    func selectTag(_ tag: String) {
        selectedTags.insert(tag)
        fetchListings() // Refresh listings with the new filter
    }

    func deselectTag(_ tag: String) {
        selectedTags.remove(tag)
        fetchListings() // Refresh listings with the new filter
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        fetchListings() // Refresh listings with the new filter
    }

    func clearTagFilters() {
        selectedTags.removeAll()
        fetchListings() // Refresh listings with the new filter
    }

    // You can also add this method to get all unique tags from current listings
    func getAllUniqueTags() -> [String] {
        var allTags = Set<String>()
        
        // Collect tags from all listings
        for listing in listings {
            allTags.formUnion(listing.typeFilters)
        }
        
        for listing in featuredListings {
            allTags.formUnion(listing.typeFilters)
        }
        
        return Array(allTags).sorted()
    }

    // Add a new method to check if a filter combination would yield results
    func wouldFiltersYieldResults(tags: Set<String>, amenities: [String: Bool]) -> Bool {
        // If no filters selected, we'll have results
        if tags.isEmpty && !amenities.values.contains(true) {
            return true
        }
        
        // Create a base query - start with CollectionReference and then convert to Query
        let collectionRef = db.collection("listings")
        var query: Query = collectionRef
        
        // Apply amenity filters (AND operation - must match all)
        for (field, isActive) in amenities {
            if isActive {
                query = query.whereField(field, isEqualTo: true)
            }
        }
        
        // For tags, we need to handle the AND operation differently
        // We'll do the first tag in Firestore and the rest client-side
        if !tags.isEmpty {
            let tagsArray = Array(tags)
            query = query.whereField("typeFilters", arrayContains: tagsArray[0])
        }
        
        // Use a semaphore to make this synchronous
        let semaphore = DispatchSemaphore(value: 0)
        var hasResults = false
        
        query.limit(to: 20).getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                // If we have multiple tags, filter client-side to ensure all tags match
                if tags.count > 1 {
                    let allTags = Array(tags)
                    let additionalTags = allTags.dropFirst() // Skip first tag (already filtered)
                    
                    // Check for documents with ALL the selected tags
                    let matchingDocs = documents.filter { document in
                        guard let documentTags = document.data()["typeFilters"] as? [String] else {
                            return false
                        }
                        
                        // Document must contain ALL additional tags
                        for tag in additionalTags {
                            if !documentTags.contains(tag) {
                                return false
                            }
                        }
                        return true
                    }
                    
                    hasResults = !matchingDocs.isEmpty
                } else {
                    // If just one tag or no tags, the Firestore query is sufficient
                    hasResults = !documents.isEmpty
                }
            }
            semaphore.signal()
        }
        
        // Wait for the result
        _ = semaphore.wait(timeout: .now() + 2.0)
        return hasResults
    }
}
