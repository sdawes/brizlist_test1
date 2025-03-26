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
    @State private var type: String
    @State private var location: String
    
    init(viewModel: ListingsViewModel, listing: Listing) {
        self.viewModel = viewModel
        self.listing = listing
        _name = State(initialValue: listing.name)
        _category = State(initialValue: listing.category)
        _description = State(initialValue: listing.description)
        _type = State(initialValue: listing.type)
        _location = State(initialValue: listing.location)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Listing Details")) {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Description", text: $description)
                    TextField("Type", text: $type)
                    TextField("Location", text: $location)                  
                }
                
                Button("Update") {
                    var updatedListing = listing
                    updatedListing.name = name
                    updatedListing.category = category
                    updatedListing.description = description
                    updatedListing.type = type
                    updatedListing.location = location
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
        type.isEmpty || 
        location.isEmpty
    }
}
