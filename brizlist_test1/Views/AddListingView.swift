//
//  AddListingView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import SwiftUI

struct AddListingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ListingsViewModel
    
    @State private var name = ""
    @State private var category = ""
    @State private var description = ""
    @State private var rating: Double = 3.0
    @State private var type = ""
    @State private var location = ""
    
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
                
                Button("Save") {
                    viewModel.addListing(
                        name: name,
                        category: category,
                        description: description,
                        type: type,
                        location: location
                    )
                    dismiss()
                }
                .disabled(name.isEmpty || category.isEmpty)
            }
            .navigationTitle("Add Listing")
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
