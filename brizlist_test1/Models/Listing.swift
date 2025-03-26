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
    var description: String
    var type: String
    var location: String
    var imageURL: String? // Optional because not all listings need images
    
    // Updated initializer with consistent required/optional parameters
    init(id: String? = nil, name: String, category: String, description: String, type: String, location: String, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.type = type
        self.location = location
        self.imageURL = imageURL
    }
}
