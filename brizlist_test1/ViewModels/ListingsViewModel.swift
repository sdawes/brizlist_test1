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
    @Published var selectedTypeFilters: Set<String> = []
    @Published var noResultsFromFiltering: Bool = false
    
    // Cache all available filters (populated after first fetch)
    private var cachedTypeFilters: [String] = []
    private var cachedTags: [String] = []
    
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
        FilterOption(field: "isNew", displayName: "New Listings"),
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
    
    // Helper to check if type filter filtering is active
    var hasTypeFilters: Bool {
        return !selectedTypeFilters.isEmpty
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
        
        // Filter by type filters if any are selected
        if !selectedTypeFilters.isEmpty {
            // For "AND" type filtering, we need to check that each document contains all selected type filters
            // We'll use multiple array-contains queries in combination with filter client-side
            
            // Start with the first type filter (we need at least one in the Firestore query)
            let typeFiltersArray = Array(selectedTypeFilters)
            query = query.whereField("typeFilters", arrayContains: typeFiltersArray[0])
            
            // We'll need to filter the rest of the type filters client-side in processQueryResults
        }
        
        // Apply all other active filters
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
        let hasActiveFilters = self.hasActiveFilters || self.hasTypeFilters
        
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
        
        // Additional client-side filtering if we have multiple type filters
        // (Firestore can only query for one array-contains at a time)
        var filteredDocuments = documents
        if selectedTypeFilters.count > 1 {
            let allTypeFilters = Array(selectedTypeFilters)
            // Skip the first type filter as it was already filtered in the query
            let additionalTypeFilters = allTypeFilters.dropFirst()
            
            // Filter documents to contain ALL the selected type filters (AND operation)
            filteredDocuments = documents.filter { document in
                guard let documentTypeFilters = document.data()["typeFilters"] as? [String] else {
                    return false
                }
                
                // Check that all additional type filters are present in the document
                for typeFilter in additionalTypeFilters {
                    if !documentTypeFilters.contains(typeFilter) {
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
        if !hasActiveFilters && !hasTypeFilters {
            cacheAllAvailableFilters(from: newListings)
        }
        
        // Sort listings to put new listings at the top
        let sortedListings = sortListingsWithNewAtTop(newListings)
        
        // We still use separateFeaturedListings for reference, but we'll include all listings in the main array
        let (featured, regular) = separateFeaturedListings(sortedListings)
        
        if isInitialFetch {
            featuredListings = featured
            listings = sortedListings  // Use all sorted listings
        } else {
            featuredListings.append(contentsOf: featured)
            listings.append(contentsOf: sortedListings)  // Use all sorted listings
            
            // Re-sort the combined list to ensure new listings are at the top
            if isInitialFetch == false {
                listings = sortListingsWithNewAtTop(listings)
            }
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
            longDescription: data["longDescription"] as? String ?? "",
            location: data["location"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            isBrizPick: data["isBrizPick"] as? Bool,
            isFeatured: data["isFeatured"] as? Bool,
            isNew: data["isNew"] as? Bool
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
    
    // Remove redundant tag selection methods, keeping only the type filter methods
    func selectTypeFilter(_ filter: String) {
        selectedTypeFilters.insert(filter)
        fetchListings() // Refresh listings with the new filter
    }

    func deselectTypeFilter(_ filter: String) {
        selectedTypeFilters.remove(filter)
        fetchListings() // Refresh listings with the new filter
    }

    func toggleTypeFilter(_ filter: String) {
        if selectedTypeFilters.contains(filter) {
            selectedTypeFilters.remove(filter)
        } else {
            selectedTypeFilters.insert(filter)
        }
        fetchListings() // Refresh listings with the new filter
    }

    func clearTypeFilters() {
        selectedTypeFilters.removeAll()
        fetchListings() // Refresh listings with the new filter
    }

    // Get all unique type filters from current listings
    func getAllUniqueTypeFilters() -> [String] {
        var allTypeFilters = Set<String>()
        
        // Collect type filters from all listings
        for listing in listings {
            allTypeFilters.formUnion(listing.typeFilters)
        }
        
        for listing in featuredListings {
            allTypeFilters.formUnion(listing.typeFilters)
        }
        
        // Filter out tag values for the type section
        return Array(allTypeFilters)
            .filter { !$0.lowercased().contains("tag") }
            .sorted()
    }
    
    // Get all tag filters (type filters that contain "tag")
    func getAllUniqueTags() -> [String] {
        var allTypeFilters = Set<String>()
        
        // Collect type filters from all listings
        for listing in listings {
            allTypeFilters.formUnion(listing.typeFilters)
        }
        
        for listing in featuredListings {
            allTypeFilters.formUnion(listing.typeFilters)
        }
        
        // Only return tag values
        return Array(allTypeFilters)
            .filter { $0.lowercased().contains("tag") }
            .sorted()
    }

    // Check if a combination of filters would yield results
    func wouldFiltersYieldResults(typeFilters: Set<String>, otherFilters: [String: Bool]) -> Bool {
        // If no filters selected, we'll have results
        if typeFilters.isEmpty && !otherFilters.values.contains(true) {
            return true
        }
        
        // Create a base query - start with CollectionReference and then convert to Query
        let collectionRef = db.collection("listings")
        var query: Query = collectionRef
        
        // Apply other filters (AND operation - must match all)
        for (field, isActive) in otherFilters {
            if isActive {
                query = query.whereField(field, isEqualTo: true)
            }
        }
        
        // For type filters, we need to handle the AND operation differently
        // We'll do the first type filter in Firestore and the rest client-side
        if !typeFilters.isEmpty {
            let typeFiltersArray = Array(typeFilters)
            query = query.whereField("typeFilters", arrayContains: typeFiltersArray[0])
        }
        
        // Use a semaphore to make this synchronous
        let semaphore = DispatchSemaphore(value: 0)
        var hasResults = false
        
        query.limit(to: 20).getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                // If we have multiple type filters, filter client-side to ensure all type filters match
                if typeFilters.count > 1 {
                    let allTypeFilters = Array(typeFilters)
                    let additionalTypeFilters = allTypeFilters.dropFirst() // Skip first filter (already filtered)
                    
                    // Check for documents with ALL the selected type filters
                    let matchingDocs = documents.filter { document in
                        guard let documentTypeFilters = document.data()["typeFilters"] as? [String] else {
                            return false
                        }
                        
                        // Document must contain ALL additional type filters
                        for typeFilter in additionalTypeFilters {
                            if !documentTypeFilters.contains(typeFilter) {
                                return false
                            }
                        }
                        return true
                    }
                    
                    hasResults = !matchingDocs.isEmpty
                } else {
                    // If just one type filter or no type filters, the Firestore query is sufficient
                    hasResults = !documents.isEmpty
                }
            }
            semaphore.signal()
        }
        
        // Wait for the result
        _ = semaphore.wait(timeout: .now() + 2.0)
        return hasResults
    }
    
    // Cache all available filters from unfiltered listings
    private func cacheAllAvailableFilters(from listings: [Listing]) {
        var typeFilters = Set<String>()
        var tags = Set<String>()
        
        for listing in listings {
            for filter in listing.typeFilters {
                if filter.lowercased().contains("tag") {
                    tags.insert(filter)
                } else {
                    typeFilters.insert(filter)
                }
            }
        }
        
        // Update cache
        self.cachedTypeFilters = Array(typeFilters)
        self.cachedTags = Array(tags)
    }
    
    // Get cached type filters (for Filter sheet)
    func getCachedTypeFilters() -> [String] {
        return cachedTypeFilters
    }
    
    // Get cached tags (for Filter sheet)
    func getCachedTags() -> [String] {
        return cachedTags
    }
    
    // Sort listings to prioritize new listings at the top
    private func sortListingsWithNewAtTop(_ listings: [Listing]) -> [Listing] {
        return listings.sorted { first, second in
            // First priority: New listings at the top
            if (first.isNew ?? false) && !(second.isNew ?? false) {
                return true
            } else if !(first.isNew ?? false) && (second.isNew ?? false) {
                return false
            }
            
            // Second priority: Featured listings
            if (first.isFeatured ?? false) && !(second.isFeatured ?? false) {
                return true
            } else if !(first.isFeatured ?? false) && (second.isFeatured ?? false) {
                return false
            }
            
            // Third priority: Alphabetically by name
            return first.name < second.name
        }
    }
}
