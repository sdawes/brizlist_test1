//
//  Listing.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore

struct Listing: Identifiable, Codable {
    @DocumentID var id: String? // Changed from String to String? to prevent warnings
    var name: String
    var category: String
    var description: String
    var rating: Double
    var type: String = "Standard"
}
