//
//  FormValidator.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/04/2025.
//

import Foundation

struct FormValidator {
    static func isFormValid(name: String, typeFilters: [String], shortDescription: String, location: String) -> Bool {
        return !name.isEmpty && !typeFilters.isEmpty && !shortDescription.isEmpty && !location.isEmpty
    }
}