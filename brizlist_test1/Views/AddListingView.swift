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
    @State private var cuisine = ""
    @State private var description = ""
    @State private var location = ""
    @State private var isVeg: Bool = false
    @State private var isDog: Bool = false
    @State private var isChild: Bool = false
    @State private var isBrizPick: Bool = false
    @State private var isSundayLunch: Bool = false
    @State private var isFeatured: Bool = false
    
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
                        let newListing = Listing(
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
                        viewModel.addListing(newListing)
                        dismiss()
                    }) {
                        Text("Save")
                    }
                    .disabled(name.isEmpty || category.isEmpty || description.isEmpty || location.isEmpty)
                }
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
