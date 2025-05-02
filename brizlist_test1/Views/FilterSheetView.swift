//
//  FilterSheetView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 29/03/2025.
//

import Foundation
import SwiftUI

struct FilterSheetView: View {
    @ObservedObject var viewModel: ListingsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Amenities Section
                Section(header: Text("Amenities")) {
                    ForEach(viewModel.availableFilters, id: \.field) { filter in
                        Toggle(filter.displayName, isOn: Binding(
                            get: { viewModel.activeFilterValues[filter.field] ?? false },
                            set: { newValue in
                                viewModel.activeFilterValues[filter.field] = newValue
                                viewModel.fetchListings()
                            }
                        ))
                    }
                }
                
                // Type Filters Section
                Section(header: Text("Type Filters")) {
                    let allTags = viewModel.getAllUniqueTags()
                    ForEach(allTags, id: \.self) { tag in
                        Toggle(tag.capitalized, isOn: Binding(
                            get: { viewModel.selectedTags.contains(tag) },
                            set: { isSelected in
                                if isSelected {
                                    viewModel.selectTag(tag)
                                } else {
                                    viewModel.deselectTag(tag)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        // Reset all filters
                        for filter in viewModel.availableFilters {
                            viewModel.activeFilterValues[filter.field] = false
                        }
                        viewModel.clearTagFilters()
                        viewModel.fetchListings()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Custom compact toggle style
struct CompactToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.blue : Color(.systemGray5))
                .frame(width: 36, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 8 : -8)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
