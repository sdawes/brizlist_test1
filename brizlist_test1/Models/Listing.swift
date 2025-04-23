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
    var category: String
    var cuisine: String // Changed from subCategory to cuisine
    var description: String
    var location: String
    var imageUrl: String? // Changed from imageURL to imageUrl to match Firestore field name
    var isBrizPick: Bool?
    var isVeg: Bool?
    var isDog: Bool?
    var isChild: Bool?
    var isSundayLunch: Bool?
    var isFeatured: Bool?
    
    // Updated initializer with consistent required/optional parameters
    init(id: String? = nil, name: String, category: String, cuisine: String = "", description: String, location: String, imageUrl: String? = nil, isBrizPick: Bool? = nil, isVeg: Bool? = nil, isDog: Bool? = nil, isChild: Bool? = nil, isSundayLunch: Bool? = nil, isFeatured: Bool? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.cuisine = cuisine
        self.description = description
        self.location = location
        self.imageUrl = imageUrl
        self.isBrizPick = isBrizPick
        self.isVeg = isVeg
        self.isDog = isDog
        self.isChild = isChild
        self.isSundayLunch = isSundayLunch
        self.isFeatured = isFeatured
    }
}
