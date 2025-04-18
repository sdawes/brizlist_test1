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
    
    // Local copy of filters for preview/editing
    @State private var localFilters: [String: Bool] = [:]
    
    // Initialize with current filters
    init(viewModel: ListingsViewModel) {
        self.viewModel = viewModel
        
        // Make a copy of the current filter values
        var initialFilters: [String: Bool] = [:]
        for filter in viewModel.availableFilters {
            initialFilters[filter.field] = viewModel.activeFilterValues[filter.field] ?? false
        }
        self._localFilters = State(initialValue: initialFilters)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filter By")) {
                    // Create a toggle for each available filter
                    ForEach(viewModel.availableFilters, id: \.field) { filter in
                        Toggle(filter.displayName, isOn: Binding(
                            get: { localFilters[filter.field] ?? false },
                            set: { localFilters[filter.field] = $0 }
                        ))
                    }
                }
                
                Section {
                    // Apply button applies all filters at once
                    Button("Apply Filters") {
                        // Update the view model with our local changes
                        for filter in viewModel.availableFilters {
                            viewModel.activeFilterValues[filter.field] = localFilters[filter.field] ?? false
                        }
                        viewModel.fetchListings()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    // Clear all button
                    Button("Clear All Filters") {
                        for filter in viewModel.availableFilters {
                            localFilters[filter.field] = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}