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
    
    // Selected card states for filtering
    @Published var selectedCardStates: Set<String> = []
    
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
        // Don't reset all data immediately - this causes the flash
        hasMoreListings = true
        
        // Check if we have any tag filters selected
        if selectedTags1.isEmpty && selectedTags2.isEmpty && selectedTags3.isEmpty && selectedCardStates.isEmpty {
            // No filters, fetch all listings
            fetchAllListings()
        } else {
            // Has filters, use query with firestore filtering and client-side filtering
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
        } else if !selectedTags2.isEmpty {
            // If no tags1 but have tags2, use first tag2 in Firestore query
            let tags2Array = Array(selectedTags2)
            query = query.whereField("tags2", arrayContains: tags2Array[0])
        } else if !selectedTags3.isEmpty {
            // If no tags1 or tags2 but have tags3, use first tag3 in Firestore query
            let tags3Array = Array(selectedTags3)
            query = query.whereField("tags3", arrayContains: tags3Array[0])
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
    
    /// Select a tag2 (secondary tag)
    func selectTag2(_ tag: String) {
        selectedTags2.insert(tag)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }

    /// Deselect a tag2 (secondary tag)
    func deselectTag2(_ tag: String) {
        selectedTags2.remove(tag)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Toggle selection of a tag2 (secondary tag)
    func toggleTag2(_ tag: String) {
        if selectedTags2.contains(tag) {
            selectedTags2.remove(tag)
        } else {
            selectedTags2.insert(tag)
        }
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Clear all tag2 selections
    func clearTags2() {
        selectedTags2.removeAll()
    }
    
    /// Select a tag3 (tertiary tag)
    func selectTag3(_ tag: String) {
        selectedTags3.insert(tag)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }

    /// Deselect a tag3 (tertiary tag)
    func deselectTag3(_ tag: String) {
        selectedTags3.remove(tag)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Toggle selection of a tag3 (tertiary tag)
    func toggleTag3(_ tag: String) {
        if selectedTags3.contains(tag) {
            selectedTags3.remove(tag)
        } else {
            selectedTags3.insert(tag)
        }
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Clear all tag3 selections
    func clearTags3() {
        selectedTags3.removeAll()
    }
    
    /// Select a card state for filtering
    func selectCardState(_ cardState: String) {
        selectedCardStates.insert(cardState)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Deselect a card state for filtering
    func deselectCardState(_ cardState: String) {
        selectedCardStates.remove(cardState)
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Toggle selection of a card state
    func toggleCardState(_ cardState: String) {
        if selectedCardStates.contains(cardState) {
            selectedCardStates.remove(cardState)
        } else {
            selectedCardStates.insert(cardState)
        }
        // Don't fetch immediately - we'll do that when 'Apply' is pressed
    }
    
    /// Clear all card state selections
    func clearCardStates() {
        selectedCardStates.removeAll()
    }
    
    /// Clear all tag selections
    func clearAllFilters() {
        selectedTags1.removeAll()
        selectedTags2.removeAll()
        selectedTags3.removeAll()
        selectedCardStates.removeAll()
        
        // Now fetch listings without filters
        fetchListings()
    }
    
    // MARK: - Helper Properties
    
    /// Check if any tag filtering is active
    var hasTagFilters: Bool {
        return !selectedTags1.isEmpty || !selectedTags2.isEmpty || !selectedTags3.isEmpty || !selectedCardStates.isEmpty
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
    
    /// Create a query with the first tag filter applied
    private func createFilteredQuery() -> Query {
        // Start with CollectionReference and then convert to Query
        let collectionRef = db.collection("listings")
        var query: Query = collectionRef.order(by: "name")
        
        // First, determine which tag collection to use for Firestore query
        if !selectedTags1.isEmpty {
            // Use the first tag1 in the Firestore query
            let tags1Array = Array(selectedTags1)
            query = query.whereField("tags1", arrayContains: tags1Array[0])
        } else if !selectedTags2.isEmpty {
            // If no tags1 but have tags2, use first tag2 in Firestore query
            let tags2Array = Array(selectedTags2)
            query = query.whereField("tags2", arrayContains: tags2Array[0])
        } else if !selectedTags3.isEmpty {
            // If no tags1 or tags2 but have tags3, use first tag3 in Firestore query
            let tags3Array = Array(selectedTags3)
            query = query.whereField("tags3", arrayContains: tags3Array[0])
        }
        
        return query.limit(to: pageSize)
    }
    
    /// Fetch data with pagination
    private func fetchData(query: Query, isInitialFetch: Bool) {
        isLoadingMore = !isInitialFetch
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            defer { self.isLoadingMore = false }
            
            if isInitialFetch {
                // Only reset the data for initial fetch, and only after we have new data
                // This prevents the screen from flashing empty content
                self.processQueryResults(snapshot: snapshot, error: error, isInitialFetch: isInitialFetch)
            } else {
                // For pagination, just append to existing data
                self.processQueryResults(snapshot: snapshot, error: error, isInitialFetch: false)
            }
        }
    }
    
    /// Sort listings alphabetically by name
    private func sortListingsByName(_ listings: [Listing]) -> [Listing] {
        return listings.sorted { first, second in
            // Sort alphabetically by name
            return first.name < second.name
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
                // Use animation for smoother transition
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.listings = []
                        self.featuredListings = []
                        
                        // Set the noResultsFromFiltering flag if we have filters but no results
                        self.noResultsFromFiltering = hasActiveFilters
                    }
                }
            }
            return
        }
        
        // Additional client-side filtering for multiple tags
        var filteredDocuments = documents
        
        // Process tags1 filtering (skip the first one if used in Firestore query)
        if selectedTags1.count > 1 {
            let allTags1 = Array(selectedTags1)
            // Skip the first tag1 as it was already filtered in the query if it exists
            let additionalTags1 = !selectedTags1.isEmpty ? Array(allTags1.dropFirst()) : allTags1
            
            // Filter documents to contain ALL the selected tags1 (AND operation)
            filteredDocuments = filteredDocuments.filter { document in
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
        
        // Process tags2 filtering (skip the first one if it was used in the Firestore query)
        if !selectedTags2.isEmpty {
            let allTags2 = Array(selectedTags2)
            // Skip the first tag2 if we used it in the Firestore query (when tags1 was empty)
            let additionalTags2 = (selectedTags1.isEmpty && selectedTags2.count > 1) ? 
                                    Array(allTags2.dropFirst()) : allTags2
            
            // Filter documents to contain ALL the selected tags2 (AND operation)
            filteredDocuments = filteredDocuments.filter { document in
                guard let documentTags2 = document.data()["tags2"] as? [String] else {
                    return false
                }
                
                // Check that all tag2 filters are present in the document
                for tag2 in additionalTags2 {
                    if !documentTags2.contains(tag2) {
                        return false
                    }
                }
                return true
            }
        }
        
        // Process tags3 filtering (skip the first one if it was used in the Firestore query)
        if !selectedTags3.isEmpty {
            let allTags3 = Array(selectedTags3)
            // Skip the first tag3 if we used it in the Firestore query (when tags1 and tags2 were empty)
            let additionalTags3 = (selectedTags1.isEmpty && selectedTags2.isEmpty && selectedTags3.count > 1) ? 
                                    Array(allTags3.dropFirst()) : allTags3
            
            // Filter documents to contain ALL the selected tags3 (AND operation)
            filteredDocuments = filteredDocuments.filter { document in
                guard let documentTags3 = document.data()["tags3"] as? [String] else {
                    return false
                }
                
                // Check that all tag3 filters are present in the document
                for tag3 in additionalTags3 {
                    if !documentTags3.contains(tag3) {
                        return false
                    }
                }
                return true
            }
        }
        
        // Process card state filtering
        if !selectedCardStates.isEmpty {
            filteredDocuments = filteredDocuments.filter { document in
                guard let cardState = document.data()["cardState"] as? String else {
                    return false
                }
                
                // Only include this document if its cardState is one of the selected ones
                return selectedCardStates.contains(cardState)
            }
        }
        
        // Check if we have results after client-side filtering
        if filteredDocuments.isEmpty {
            hasMoreListings = false
            if isInitialFetch {
                // Use animation for smoother transition
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.listings = []
                        self.featuredListings = []
                        
                        // Set the noResultsFromFiltering flag
                        self.noResultsFromFiltering = hasActiveFilters
                    }
                }
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
        
        // Sort listings alphabetically (no longer prioritize new listings)
        let sortedListings = sortListingsByName(newListings)
        
        // We still use separateFeaturedListings for UI reference but we won't sort by featured status
        let (featured, _) = separateFeaturedListings(sortedListings)
        
        if isInitialFetch {
            // Apply results with animation for a smoother transition
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.featuredListings = featured
                    self.listings = sortedListings  // Use all sorted listings
                    
                    // Found results, so reset the no results flag
                    self.noResultsFromFiltering = false
                }
            }
        } else {
            // For pagination, just append to existing data
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.featuredListings.append(contentsOf: featured)
                    self.listings.append(contentsOf: sortedListings)  // Append the new sorted listings
                    
                    // Re-sort the combined list if needed
                    if isInitialFetch == false {
                        self.listings = self.sortListingsByName(self.listings)
                    }
                    
                    // Found results, so reset the no results flag
                    self.noResultsFromFiltering = false
                }
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
}
