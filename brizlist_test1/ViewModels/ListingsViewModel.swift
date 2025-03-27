//
//  ListingsViewModel.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class ListingsViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isLoadingMoreListings: Bool = false
    @Published var hasMoreListings: Bool = true
    
    private let db = Firestore.firestore()
    private let pageSize = 10 // Number of listings per page
    private var lastDocument: DocumentSnapshot?
    
    // Read Listings
    
    func fetchListings() {
        // Clear existing listings and reset pagination state
        listings = []
        lastDocument = nil
        hasMoreListings = true
        
        // Set up initial query with limit
        db.collection("listings")
            .order(by: "name")
            .limit(to: pageSize)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error fetching listings: \(error.localizedDescription)"
                    self.showError = true
                    print("❌ Error fetching listings: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // No documents found
                    self.listings = []
                    self.hasMoreListings = false
                    return
                }
                
                // Save the last document for pagination
                self.lastDocument = documents.last
                
                // Check if we've reached the end
                if documents.count < self.pageSize {
                    self.hasMoreListings = false
                } else {
                    self.hasMoreListings = true
                }
                
                // Manual decoding
                self.listings = documents.compactMap { document in
                    let data = document.data()
                    let id = document.documentID
                    
                    // Check if all required fields exist
                    guard 
                        let name = data["name"] as? String,
                        let category = data["category"] as? String,
                        let description = data["description"] as? String,
                        let type = data["type"] as? String,
                        let location = data["location"] as? String
                    else {
                        print("❌ Skipping document \(id) due to missing required fields")
                        return nil
                    }
                    
                    // imageURL remains optional
                    let imageURL = data["imageURL"] as? String
                    let isBrizPick = data["isBrizPick"] as? Bool
                    let isVegan = data["isVegan"] as? Bool
                    let isVeg = data["isVeg"] as? Bool
                    let isDog = data["isDog"] as? Bool
                    let isChild = data["isChild"] as? Bool
                    
                    return Listing(
                        id: id,
                        name: name,
                        category: category,
                        description: description,
                        type: type,
                        location: location,
                        imageURL: imageURL,
                        isBrizPick: isBrizPick,
                        isVegan: isVegan,
                        isVeg: isVeg,
                        isDog: isDog,
                        isChild: isChild
                    )
                }
            }
    }

    func loadMoreListings() {
        // If we're already loading or there are no more listings, return
        if isLoadingMoreListings || !hasMoreListings || lastDocument == nil {
            return
        }
        
        isLoadingMoreListings = true
        
        // Create query for next batch
        db.collection("listings")
            .order(by: "name")
            .limit(to: pageSize)
            .start(afterDocument: lastDocument!)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoadingMoreListings = false
                
                if let error = error {
                    self.errorMessage = "Error loading more listings: \(error.localizedDescription)"
                    self.showError = true
                    print("❌ Error loading more listings: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // No more documents to load
                    self.hasMoreListings = false
                    return
                }
                
                // Save the last document for pagination
                self.lastDocument = documents.last
                
                // Check if we've reached the end
                if documents.count < self.pageSize {
                    self.hasMoreListings = false
                }
                
                // Manual decoding
                let newListings = documents.compactMap { document -> Listing? in
                    let data = document.data()
                    let id = document.documentID
                    
                    // Check if all required fields exist
                    guard 
                        let name = data["name"] as? String,
                        let category = data["category"] as? String,
                        let description = data["description"] as? String,
                        let type = data["type"] as? String,
                        let location = data["location"] as? String
                    else {
                        print("❌ Skipping document \(id) due to missing required fields")
                        return nil
                    }
                    
                    let imageURL = data["imageURL"] as? String
                    let isBrizPick = data["isBrizPick"] as? Bool
                    let isVegan = data["isVegan"] as? Bool
                    let isVeg = data["isVeg"] as? Bool
                    let isDog = data["isDog"] as? Bool
                    let isChild = data["isChild"] as? Bool
                    
                    return Listing(
                        id: id,
                        name: name,
                        category: category,
                        description: description,
                        type: type,
                        location: location,
                        imageURL: imageURL,
                        isBrizPick: isBrizPick,
                        isVegan: isVegan,
                        isVeg: isVeg,
                        isDog: isDog,
                        isChild: isChild
                    )
                }
                
                // Append new listings to existing ones
                self.listings.append(contentsOf: newListings)
            }
    }

    // Add Listings
    
    func addListing(name: String, 
                    category: String, 
                    description: String, 
                    type: String, 
                    location: String, 
                    isBrizPick: Bool? = nil,
                    isVegan: Bool? = nil,
                    isVeg: Bool? = nil,
                    isDog: Bool? = nil,
                    isChild: Bool? = nil) {
        
        // Create data dictionary
        var data: [String: Any] = [
            "name": name,
            "category": category,
            "description": description,
            "type": type,
            "location": location
        ]
        
        // Add optional fields if they exist
        if let isBrizPick = isBrizPick { data["isBrizPick"] = isBrizPick }
        if let isVegan = isVegan { data["isVegan"] = isVegan }
        if let isVeg = isVeg { data["isVeg"] = isVeg }
        if let isDog = isDog { data["isDog"] = isDog }
        if let isChild = isChild { data["isChild"] = isChild }
        
        // Create a new listing with the provided data
        let newListingRef = db.collection("listings").document()
        let newListingId = newListingRef.documentID
        
        let newListing = Listing(
            id: newListingId,
            name: name,
            category: category,
            description: description,
            type: type,
            location: location,
            isBrizPick: isBrizPick,
            isVegan: isVegan,
            isVeg: isVeg,
            isDog: isDog,
            isChild: isChild
        )
        
        // Add to Firestore
        newListingRef.setData(data) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "Error adding listing: \(error.localizedDescription)"
                self.showError = true
                print("❌ Error adding listing: \(error)")
            }
        }
    }

    // Update Listings
    
    func updateListing(listing: Listing) {
        guard let id = listing.id else {
            errorMessage = "Error updating listing: Missing ID"
            showError = true
            return
        }
        
        var data: [String: Any] = [
            "name": listing.name,
            "category": listing.category,
            "description": listing.description,
            "type": listing.type,
            "location": listing.location
        ]
        
        if let isBrizPick = listing.isBrizPick { data["isBrizPick"] = isBrizPick }
        if let isVegan = listing.isVegan { data["isVegan"] = isVegan }
        if let isVeg = listing.isVeg { data["isVeg"] = isVeg }
        if let isDog = listing.isDog { data["isDog"] = isDog }
        if let isChild = listing.isChild { data["isChild"] = isChild }
        
        db.collection("listings").document(id).updateData(data) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "Error updating listing: \(error.localizedDescription)"
                self.showError = true
                print("❌ Error updating listing: \(error)")
            }
        }
    }

    // Delete Listings
    
    func deleteListing(listing: Listing) {
        // Safely unwrap the optional id
        guard let documentId = listing.id else {
            self.errorMessage = "Error deleting listing: Missing document ID"
            self.showError = true
            print("❌ Error deleting listing: Missing document ID")
            return
        }
        
        db.collection("listings").document(documentId).delete { error in
            if let error = error {
                self.errorMessage = "Error deleting listing: \(error.localizedDescription)"
                self.showError = true
                print("❌ Error deleting listing: \(error)")
            }
        }
    }
}
