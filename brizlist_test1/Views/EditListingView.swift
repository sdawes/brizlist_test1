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
    @State private var description: String
    @State private var location: String
    @State private var isVegan: Bool
    @State private var isVeg: Bool
    @State private var isDog: Bool
    @State private var isChild: Bool
    @State private var isBrizPick: Bool
    
    init(viewModel: ListingsViewModel, listing: Listing) {
        self.viewModel = viewModel
        self.listing = listing
        _name = State(initialValue: listing.name)
        _category = State(initialValue: listing.category)
        _description = State(initialValue: listing.description)
        _location = State(initialValue: listing.location)
        _isVegan = State(initialValue: listing.isVegan ?? false)
        _isVeg = State(initialValue: listing.isVeg ?? false)
        _isDog = State(initialValue: listing.isDog ?? false)
        _isChild = State(initialValue: listing.isChild ?? false)
        _isBrizPick = State(initialValue: listing.isBrizPick ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Listing Details")) {
                    TextField("Name of business", text: $name)
                    TextField("Category", text: $category)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                }

                Section(header: Text("Features")) {
                    Toggle("Vegan Friendly", isOn: $isVegan)
                    Toggle("Vegetarian Friendly", isOn: $isVeg)
                    Toggle("Dog Friendly", isOn: $isDog)
                    Toggle("Child Friendly", isOn: $isChild)
                    Toggle("Briz Pick", isOn: $isBrizPick)
                }
                
                Button("Update") {
                    var updatedListing = listing
                    updatedListing.name = name
                    updatedListing.category = category
                    updatedListing.description = description
                    updatedListing.location = location
                    updatedListing.isVegan = isVegan
                    updatedListing.isVeg = isVeg
                    updatedListing.isDog = isDog
                    updatedListing.isChild = isChild
                    updatedListing.isBrizPick = isBrizPick
                    viewModel.updateListing(listing: updatedListing)
                    dismiss()
                }
                .disabled(name.isEmpty || category.isEmpty)
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

    // Computed property to check if form is valid
    private var isFormInvalid: Bool {
        name.isEmpty || 
        category.isEmpty || 
        description.isEmpty || 
        location.isEmpty
    }
}
