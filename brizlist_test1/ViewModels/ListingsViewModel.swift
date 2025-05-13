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
    @Published var noResultsFromFiltering: Bool = false
    
    // MARK: - Filtering Properties
    // Selected tags for filtering (public for UI binding)
    @Published var selectedTags1: Set<String> = []
    // Keep references to these properties for future development
    @Published var selectedTags2: Set<String> = []
    @Published var selectedTags3: Set<String> = []
    
    // Cache available tags for filter UI
    private var cachedTags1: [String] = []
    private var cachedTags2: [String] = []
    private var cachedTags3: [String] = []
    private var cachedTags: [String] = []
    
    // Firebase connection
    private let db = Firestore.firestore()
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    private var listener: ListenerRegistration?
    
    init() {
        fetchInitialListings()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Public Methods
    
    /// Fetch listings from Firebase with current filters applied
    public func fetchListings() {
        resetPaginationState()
        
        // Check if we have any tag1 filters selected
        if selectedTags1.isEmpty {
            // No filters, fetch all listings
            fetchAllListings()
        } else {
            // Has filters, use query with first tag and client-side filtering
            fetchData(query: createFilteredQuery(), isInitialFetch: true)
        }
    }
    
    /// Load more listings for pagination
    public func loadMoreListings() {
        guard canLoadMore, let lastDoc = lastDocument else { return }
        isLoadingMore = true
        
        var query = db.collection("listings")
            .order(by: "name")
            .start(afterDocument: lastDoc)
            .limit(to: pageSize)
        
        // Add filter if we have selected tags
        if !selectedTags1.isEmpty {
            // Add the first tag1 filter to the query
            let tags1Array = Array(selectedTags1)
            query = query.whereField("tags1", arrayContains: tags1Array[0])
        }
        
        fetchData(query: query, isInitialFetch: false)
    }
    
    // MARK: - Tag Selection Methods
    
    /// Select a tag1 (primary tag)
    func selectTag1(_ tag: String) {
        selectedTags1.insert(tag)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }

    /// Deselect a tag1 (primary tag)
    func deselectTag1(_ tag: String) {
        selectedTags1.remove(tag)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Toggle selection of a tag1 (primary tag)
    func toggleTag1(_ tag: String) {
        if selectedTags1.contains(tag) {
            selectedTags1.remove(tag)
        } else {
            selectedTags1.insert(tag)
        }
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Clear all tag1 selections
    func clearTags1() {
        selectedTags1.removeAll()
    }
    
    /// Clear all tag selections
    func clearAllFilters() {
        selectedTags1.removeAll()
        selectedTags2.removeAll()
        selectedTags3.removeAll()
        
        // Now fetch listings without filters
        fetchListings()
    }
    
    // MARK: - Helper Properties
    
    /// Check if any tag filtering is active
    var hasTagFilters: Bool {
        return !selectedTags1.isEmpty
    }
    
    /// Check if any filtering is active
    var isFiltering: Bool {
        return hasTagFilters
    }
    
    /// Check if more listings can be loaded
    private var canLoadMore: Bool {
        !isLoadingMore && hasMoreListings && lastDocument != nil
    }
    
    // MARK: - Tag Getter Methods
    
    /// Get all unique tag1 values from current listings
    func getAllUniqueTags1() -> [String] {
        var allTags1 = Set<String>()
        
        // Collect tags1 from all listings
        for listing in listings {
            allTags1.formUnion(listing.tags1)
        }
        
        for listing in featuredListings {
            allTags1.formUnion(listing.tags1)
        }
        
        // Filter out tag values for the type section
        return Array(allTags1)
            .filter { !$0.lowercased().contains("tag") }
            .sorted()
    }
    
    /// Get all unique tag2 values from current listings
    func getAllUniqueTags2() -> [String] {
        var allTags2 = Set<String>()
        
        // Collect tags2 from all listings
        for listing in listings {
            allTags2.formUnion(listing.tags2)
        }
        
        for listing in featuredListings {
            allTags2.formUnion(listing.tags2)
        }
        
        return Array(allTags2).sorted()
    }
    
    /// Get all unique tag3 values from current listings
    func getAllUniqueTags3() -> [String] {
        var allTags3 = Set<String>()
        
        // Collect tags3 from all listings
        for listing in listings {
            allTags3.formUnion(listing.tags3)
        }
        
        for listing in featuredListings {
            allTags3.formUnion(listing.tags3)
        }
        
        return Array(allTags3).sorted()
    }
    
    // Get all tag filters (type filters that contain "tag")
    func getAllUniqueTags() -> [String] {
        var allTags1 = Set<String>()
        
        // Collect tags1 from all listings
        for listing in listings {
            allTags1.formUnion(listing.tags1)
        }
        
        for listing in featuredListings {
            allTags1.formUnion(listing.tags1)
        }
        
        // Only return tag values
        return Array(allTags1)
            .filter { $0.lowercased().contains("tag") }
            .sorted()
    }
    
    /// Get cached tag1 values
    func getCachedTags1() -> [String] {
        return cachedTags1
    }
    
    /// Get cached tag2 values
    func getCachedTags2() -> [String] {
        return cachedTags2
    }
    
    /// Get cached tag3 values
    func getCachedTags3() -> [String] {
        return cachedTags3
    }
    
    /// Get cached tags values
    func getCachedTags() -> [String] {
        return cachedTags
    }
    
    // MARK: - Private Methods
    
    /// Reset pagination state for fresh listing fetch
    private func resetPaginationState() {
        listings = []
        featuredListings = []
        lastDocument = nil
        hasMoreListings = true
    }
    
    /// Fetch all listings without any filters (for initial load)
    private func fetchInitialListings() {
        let query = db.collection("listings")
            .order(by: "name")
            .limit(to: pageSize)
        
        fetchData(query: query, isInitialFetch: true)
    }
    
    /// Fetch all listings without any filters
    private func fetchAllListings() {
        let query = db.collection("listings")
            .order(by: "name")
            .limit(to: pageSize)
        
        fetchData(query: query, isInitialFetch: true)
    }
    
    /// Create a query with the first tag1 filter applied
    private func createFilteredQuery() -> Query {
        // Start with CollectionReference and then convert to Query
        let collectionRef = db.collection("listings")
        var query: Query = collectionRef.order(by: "name")
        
        // Filter by tags1 if any are selected
        if !selectedTags1.isEmpty {
            // Use the first tag1 in the Firestore query
            let tags1Array = Array(selectedTags1)
            query = query.whereField("tags1", arrayContains: tags1Array[0])
        }
        
        return query.limit(to: pageSize)
    }
    
    /// Fetch data with pagination
    private func fetchData(query: Query, isInitialFetch: Bool) {
        isLoadingMore = !isInitialFetch
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            defer { self.isLoadingMore = false }
            
            self.processQueryResults(snapshot: snapshot, error: error, isInitialFetch: isInitialFetch)
        }
    }
    
    /// Process query results from Firestore
    private func processQueryResults(snapshot: QuerySnapshot?, error: Error?, isInitialFetch: Bool) {
        if let error = error {
            handleFirestoreError(error, message: "Error fetching listings")
            return
        }
        
        // Check if we have any filters active 
        let hasActiveFilters = self.hasTagFilters
        
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
        
        // Additional client-side filtering if we have multiple tags1
        // (Firestore can only query for one array-contains at a time)
        var filteredDocuments = documents
        if selectedTags1.count > 1 {
            let allTags1 = Array(selectedTags1)
            // Skip the first tag1 as it was already filtered in the query
            let additionalTags1 = allTags1.dropFirst()
            
            // Filter documents to contain ALL the selected tags1 (AND operation)
            filteredDocuments = documents.filter { document in
                guard let documentTags1 = document.data()["tags1"] as? [String] else {
                    return false
                }
                
                // Check that all additional tag1 filters are present in the document
                for tag1 in additionalTags1 {
                    if !documentTags1.contains(tag1) {
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
        
        // Update cached filters if we're fetching without filters
        if !hasTagFilters {
            cacheAllTagsAndFilters(from: newListings)
        }
        
        // Sort listings to prioritize new listings at the top, then alphabetically
        let sortedListings = sortListingsWithNewAtTop(newListings)
        
        // We still use separateFeaturedListings for UI reference but we won't sort by featured status
        let (featured, _) = separateFeaturedListings(sortedListings)
        
        if isInitialFetch {
            featuredListings = featured
            listings = sortedListings  // Use all sorted listings
        } else {
            featuredListings.append(contentsOf: featured)
            listings.append(contentsOf: sortedListings)  // Append the new sorted listings
            
            // Re-sort the combined list
            if isInitialFetch == false {
                listings = sortListingsWithNewAtTop(listings)
            }
        }
    }
    
    /// Create a Listing object from a Firestore document
    private func createListingFromDocument(_ document: QueryDocumentSnapshot) -> Listing? {
        let data = document.data()
        
        return Listing(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            tags1: data["tags1"] as? [String] ?? [],
            tags2: data["tags2"] as? [String] ?? [],
            tags3: data["tags3"] as? [String] ?? [],
            shortDescription: data["shortDescription"] as? String ?? "",
            longDescription: data["longDescription"] as? String ?? "",
            location: data["location"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            isBrizPick: data["isBrizPick"] as? Bool,
            cardState: data["cardState"] as? String ?? "default"
        )
    }
    
    /// Handle Firestore errors
    private func handleFirestoreError(_ error: Error?, message: String) {
        if let error = error {
            errorMessage = "\(message): \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Separate featured listings from regular listings
    private func separateFeaturedListings(_ listings: [Listing]) -> (featured: [Listing], regular: [Listing]) {
        var featured: [Listing] = []
        var regular: [Listing] = []
        
        for listing in listings {
            if listing.isFeatured {
                featured.append(listing)
            } else {
                regular.append(listing)
            }
        }
        
        return (featured, regular)
    }
    
    /// Cache all available tags from listings
    private func cacheAllTagsAndFilters(from listings: [Listing]) {
        var tags1 = Set<String>()
        var tags2 = Set<String>()
        var tags3 = Set<String>()
        var tags = Set<String>()
        
        for listing in listings {
            // Process tags1
            for filter in listing.tags1 {
                if filter.lowercased().contains("tag") {
                    tags.insert(filter)
                } else {
                    tags1.insert(filter)
                }
            }
            
            // Process tags2
            tags2.formUnion(listing.tags2)
            
            // Process tags3
            tags3.formUnion(listing.tags3)
        }
        
        // Update cache
        self.cachedTags1 = Array(tags1)
        self.cachedTags2 = Array(tags2)
        self.cachedTags3 = Array(tags3)
        self.cachedTags = Array(tags)
    }
    
    /// Sort listings with new listings at the top, then alphabetically
    private func sortListingsWithNewAtTop(_ listings: [Listing]) -> [Listing] {
        return listings.sorted { first, second in
            // First priority: New listings at the top
            if first.isNew && !second.isNew {
                return true
            } else if !first.isNew && second.isNew {
                return false
            }
            
            // Everything else sorted alphabetically by name
            return first.name < second.name
        }
    }
}
