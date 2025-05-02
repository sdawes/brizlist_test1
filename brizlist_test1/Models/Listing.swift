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
    var typeFilters: [String]  // Renamed from tags
    var cuisine: String 
    var shortDescription: String  // Renamed from description
    var longDescription: String  // New field for detailed description
    var location: String
    var imageUrl: String?
    var isBrizPick: Bool?
    var isFeatured: Bool?
    var isNew: Bool?  // New field to indicate if a listing is new
    
    // Helper to get a displayable URL
    var displayImageUrl: URL? {
        guard let urlString = imageUrl else { return nil }
        return URL(string: urlString)
    }
    
    // Updated initializer with consistent required/optional parameters
    init(id: String? = nil, name: String, typeFilters: [String] = [], cuisine: String = "", shortDescription: String, longDescription: String = "", location: String, imageUrl: String? = nil, isBrizPick: Bool? = nil, isFeatured: Bool? = nil, isNew: Bool? = nil) {
        self.id = id
        self.name = name
        self.typeFilters = typeFilters
        self.cuisine = cuisine
        self.shortDescription = shortDescription
        self.longDescription = longDescription
        self.location = location
        self.imageUrl = imageUrl
        self.isBrizPick = isBrizPick
        self.isFeatured = isFeatured
        self.isNew = isNew
    }
}
