//
//  CuratedListViewModel.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 31/05/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

/// ViewModel responsible for managing CuratedList data and Firestore interactions
class CuratedListViewModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var curatedLists: [CuratedList] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // Cache for curated list listings to avoid repeated fetches
    private var curatedListingsCache: [String: [Listing]] = [:]
    
    // Firebase connection
    private let db = Firestore.firestore()
    
    init() {
        fetchCuratedLists()
    }
    
    // MARK: - Public Methods
    
    /// Fetch all active curated lists from Firestore
    func fetchCuratedLists() {
        print("DEBUG: Starting to fetch curated lists...")
        isLoading = true
        
        db.collection("curatedLists")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("DEBUG: Error fetching curated lists: \(error.localizedDescription)")
                        self.handleError(error, message: "Error fetching curated lists")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("DEBUG: No curated list documents found")
                        self.curatedLists = []
                        return
                    }
                    
                    print("DEBUG: Found \(documents.count) curated list documents")
                    for doc in documents {
                        print("DEBUG: Document ID: \(doc.documentID), Data: \(doc.data())")
                    }
                    
                    self.curatedLists = documents.compactMap(self.createCuratedListFromDocument)
                        .sorted { $0.displayOrder < $1.displayOrder }
                    print("DEBUG: Successfully parsed \(self.curatedLists.count) curated lists")
                    
                    for list in self.curatedLists {
                        print("DEBUG: Parsed list - Title: '\(list.title)', Active: \(list.isActive), ListingIDs: \(list.listingIds)")
                    }
                }
            }
    }
    
    /// Fetch listings for a specific curated list
    func fetchListingsForCuratedList(_ curatedList: CuratedList, completion: @escaping ([Listing]) -> Void) {
        // Check cache first
        if let cachedListings = curatedListingsCache[curatedList.id ?? ""] {
            completion(cachedListings)
            return
        }
        
        guard !curatedList.listingIds.isEmpty else {
            completion([])
            return
        }
        
        // Firestore 'in' queries are limited to 10 items, so we need to batch if more than 10
        let batchSize = 10
        let batches = curatedList.listingIds.chunked(into: batchSize)
        var allListings: [Listing] = []
        let dispatchGroup = DispatchGroup()
        
        for batch in batches {
            dispatchGroup.enter()
            
            db.collection("listings")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments { [weak self] snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.handleError(error, message: "Error fetching curated list listings")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let batchListings = documents.compactMap(self.createListingFromDocument)
                    allListings.append(contentsOf: batchListings)
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Sort listings to match the order in curatedList.listingIds
            let sortedListings = self.sortListingsByOrder(allListings, order: curatedList.listingIds)
            
            // Cache the results
            self.curatedListingsCache[curatedList.id ?? ""] = sortedListings
            
            completion(sortedListings)
        }
    }
    
    /// Get a specific curated list by ID
    func getCuratedList(by id: String) -> CuratedList? {
        return curatedLists.first { $0.id == id }
    }
    
    /// Clear the cache (useful for refreshing data)
    func clearCache() {
        curatedListingsCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Create a CuratedList object from a Firestore document
    private func createCuratedListFromDocument(_ document: QueryDocumentSnapshot) -> CuratedList? {
        let data = document.data()
        
        // Parse timestamps from Firestore
        var createdAt: Date? = nil
        var updatedAt: Date? = nil
        
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        }
        
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        }
        
        return CuratedList(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isActive: data["isActive"] as? Bool ?? true,
            displayOrder: data["displayOrder"] as? Int ?? 0,
            listingIds: data["listingIds"] as? [String] ?? []
        )
    }
    
    /// Create a Listing object from a Firestore document (reused from ListingsViewModel logic)
    private func createListingFromDocument(_ document: QueryDocumentSnapshot) -> Listing? {
        let data = document.data()
        
        // Parse openingDate from Firestore Timestamp
        var openingDate: Date? = nil
        if let timestamp = data["openingDate"] as? Timestamp {
            openingDate = timestamp.dateValue()
        }
        
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
            additionalImages: data["additionalImages"] as? [String] ?? [],
            cardState: data["cardState"] as? String ?? "default",
            openingDate: openingDate
        )
    }
    
    /// Sort listings to match the order specified in the curated list
    private func sortListingsByOrder(_ listings: [Listing], order: [String]) -> [Listing] {
        var sortedListings: [Listing] = []
        
        // Add listings in the order specified by the curated list
        for listingId in order {
            if let listing = listings.first(where: { $0.id == listingId }) {
                sortedListings.append(listing)
            }
        }
        
        return sortedListings
    }
    
    /// Handle Firestore errors
    private func handleError(_ error: Error, message: String) {
        errorMessage = "\(message): \(error.localizedDescription)"
        showError = true
    }
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

