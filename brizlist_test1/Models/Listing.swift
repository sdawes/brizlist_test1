//
//  Listing.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore

struct Listing: Identifiable, Codable {
    @DocumentID var id: String? // Optional because Firebase generates this automatically
    var name: String
    var tags1: [String]  // Renamed from typeFilters
    var tags2: [String]  // New field for secondary tags
    var tags3: [String]  // New field for tertiary tags
    var shortDescription: String  // Renamed from description
    var longDescription: String  // New field for detailed description
    var location: String
    var imageUrl: String?
    var cardState: String  // New field that replaces isFeatured and isNew
    
    // Helper to get a displayable URL
    var displayImageUrl: URL? {
        guard let urlString = imageUrl else { return nil }
        return URL(string: urlString)
    }
    
    // Helper properties to check card state
    var isNew: Bool {
        return cardState == "new"
    }
    
    var isFeatured: Bool {
        return cardState == "featured"
    }
    
    // Updated initializer with consistent required/optional parameters
    init(id: String? = nil, name: String, tags1: [String] = [], tags2: [String] = [], tags3: [String] = [], shortDescription: String, longDescription: String = "", location: String, imageUrl: String? = nil, cardState: String = "default") {
        self.id = id
        self.name = name
        self.tags1 = tags1
        self.tags2 = tags2
        self.tags3 = tags3
        self.shortDescription = shortDescription
        self.longDescription = longDescription
        self.location = location
        self.imageUrl = imageUrl
        self.cardState = cardState
    }
}
