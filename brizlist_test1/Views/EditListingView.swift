//
//  EditListingView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import SwiftUI

struct EditListingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ListingsViewModel
    var listing: Listing
    
    @State private var name: String
    @State private var category: String
    @State private var cuisine: String
    @State private var description: String
    @State private var location: String
    @State private var isVeg: Bool
    @State private var isDog: Bool
    @State private var isChild: Bool
    @State private var isBrizPick: Bool
    @State private var isSundayLunch: Bool
    @State private var isFeatured: Bool
    
    init(viewModel: ListingsViewModel, listing: Listing) {
        self.viewModel = viewModel
        self.listing = listing
        _name = State(initialValue: listing.name)
        _category = State(initialValue: listing.category)
        _cuisine = State(initialValue: listing.cuisine)
        _description = State(initialValue: listing.description)
        _location = State(initialValue: listing.location)
        _isVeg = State(initialValue: listing.isVeg ?? false)
        _isDog = State(initialValue: listing.isDog ?? false)
        _isChild = State(initialValue: listing.isChild ?? false)
        _isBrizPick = State(initialValue: listing.isBrizPick ?? false)
        _isSundayLunch = State(initialValue: listing.isSundayLunch ?? false)
        _isFeatured = State(initialValue: listing.isFeatured ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Listing Details")) {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Cuisine", text: $cuisine)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                }

                Section(header: Text("Features")) {
                    Toggle("Vegetarian Friendly", isOn: $isVeg)
                    Toggle("Dog Friendly", isOn: $isDog)
                    Toggle("Child Friendly", isOn: $isChild)
                    Toggle("Briz Pick", isOn: $isBrizPick)
                    Toggle("Sunday Lunch", isOn: $isSundayLunch)
                    Toggle("Featured", isOn: $isFeatured)
                }
                
                Section {
                    Button(action: {
                        let updatedListing = Listing(
                            id: listing.id,
                            name: name,
                            category: category,
                            cuisine: cuisine,
                            description: description,
                            location: location,
                            isBrizPick: isBrizPick,
                            isVeg: isVeg,
                            isDog: isDog,
                            isChild: isChild,
                            isSundayLunch: isSundayLunch,
                            isFeatured: isFeatured
                        )
                        viewModel.updateListing(updatedListing)
                        dismiss()
                    }) {
                        Text("Save")
                    }
                    .disabled(name.isEmpty || category.isEmpty || description.isEmpty || location.isEmpty)
                }
            }
            .navigationTitle("Edit Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
