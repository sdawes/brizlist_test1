//
//  CuratedList.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 31/05/2025.
//

import Foundation
import FirebaseFirestore

struct CuratedList: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID
    var title: String
    var description: String
    var imageUrl: String?
    var createdAt: Date?
    var updatedAt: Date?
    var isActive: Bool
    var displayOrder: Int
    var listingIds: [String] // Array of listing document IDs
    
    // Helper to get a displayable URL
    var displayImageUrl: URL? {
        guard let urlString = imageUrl else { return nil }
        return URL(string: urlString)
    }
    
    // Initializer
    init(id: String? = nil, title: String, description: String, imageUrl: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, isActive: Bool = true, displayOrder: Int = 0, listingIds: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
        self.displayOrder = displayOrder
        self.listingIds = listingIds
    }
}

