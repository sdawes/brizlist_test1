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
    // Add a state for selected tags
    @State private var localSelectedTags: Set<String> = []
    // Add state to track if current selection would yield results
    @State private var wouldYieldResults: Bool = true
    @State private var isCheckingResults: Bool = false
    
    // Initialize with current filters
    init(viewModel: ListingsViewModel) {
        self.viewModel = viewModel
        
        // Make a copy of the current filter values
        var initialFilters: [String: Bool] = [:]
        for filter in viewModel.availableFilters {
            initialFilters[filter.field] = viewModel.activeFilterValues[filter.field] ?? false
        }
        self._localFilters = State(initialValue: initialFilters)
        self._localSelectedTags = State(initialValue: viewModel.selectedTags)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Tag filter section
                Section(header: Text("Filter by Tags")) {
                    // Use a static list of all possible tags instead of getting from current results
                    let allPossibleTags = ["bakery", "cafe", "store", "wine bar", "pizzeria", "pub", "restaurant", "coffee shop"]
                    
                    // Calculate left and right columns
                    let leftColumnTags = stride(from: 0, to: allPossibleTags.count, by: 2).map { allPossibleTags[min($0, allPossibleTags.count - 1)] }
                    let rightColumnTags = stride(from: 1, to: allPossibleTags.count, by: 2).map { allPossibleTags[min($0, allPossibleTags.count - 1)] }
                    let maxCount = max(leftColumnTags.count, rightColumnTags.count)
                    
                    // Create the grid container
                    HStack(alignment: .top, spacing: 0) {
                        // Left column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < leftColumnTags.count {
                                    tagToggleRow(tag: leftColumnTags[index], 
                                               isSelected: localSelectedTags.contains(leftColumnTags[index])) { isOn in
                                        if isOn {
                                            localSelectedTags.insert(leftColumnTags[index])
                                        } else {
                                            localSelectedTags.remove(leftColumnTags[index])
                                        }
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Center divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)
                            .padding(.vertical, 4)
                        
                        // Right column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < rightColumnTags.count {
                                    tagToggleRow(tag: rightColumnTags[index], 
                                               isSelected: localSelectedTags.contains(rightColumnTags[index])) { isOn in
                                        if isOn {
                                            localSelectedTags.insert(rightColumnTags[index])
                                        } else {
                                            localSelectedTags.remove(rightColumnTags[index])
                                        }
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16) // Add more space at the start of the right column
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Filter By Amenities")) {
                    // Create two columns for amenity filters
                    let filters = viewModel.availableFilters
                    let leftFilters = stride(from: 0, to: filters.count, by: 2).map { filters[min($0, filters.count - 1)] }
                    let rightFilters = stride(from: 1, to: filters.count, by: 2).map { filters[min($0, filters.count - 1)] }
                    let maxCount = max(leftFilters.count, rightFilters.count)
                    
                    // Create the grid container
                    HStack(alignment: .top, spacing: 0) {
                        // Left column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < leftFilters.count {
                                    amenityToggleRow(filter: leftFilters[index], 
                                                   isSelected: localFilters[leftFilters[index].field] ?? false) { isOn in
                                        localFilters[leftFilters[index].field] = isOn
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Center divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)
                            .padding(.vertical, 4)
                        
                        // Right column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < rightFilters.count {
                                    amenityToggleRow(filter: rightFilters[index], 
                                                   isSelected: localFilters[rightFilters[index].field] ?? false) { isOn in
                                        localFilters[rightFilters[index].field] = isOn
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16) // Add more space at the start of the right column
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    // Explain the filtering logic to users
                    if localSelectedTags.count > 1 || localFilters.values.contains(true) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .padding(.top, 2)
                            
                            Text("Selected filters work as 'AND' conditions - listings must match ALL selected criteria")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Show warning if the filter combination wouldn't yield results
                    if !wouldYieldResults {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No listings match all selected criteria")
                                    .foregroundColor(.orange)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                
                                Text("Try selecting fewer filters or a different combination")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Apply button applies all filters at once
                    Button("Apply Filters") {
                        // Update the view model with our local changes
                        for filter in viewModel.availableFilters {
                            viewModel.activeFilterValues[filter.field] = localFilters[filter.field] ?? false
                        }
                        
                        // Update selected tags
                        viewModel.selectedTags = localSelectedTags
                        
                        viewModel.fetchListings()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(isCheckingResults || (!wouldYieldResults && (localSelectedTags.count > 0 || localFilters.values.contains(true))))
                    .opacity(wouldYieldResults ? 1.0 : 0.5)
                    
                    // Clear all button
                    Button("Clear All Filters and Apply") {
                        // Clear all local filters
                        for filter in viewModel.availableFilters {
                            localFilters[filter.field] = false
                        }
                        localSelectedTags.removeAll()
                        
                        // Apply changes to view model
                        for filter in viewModel.availableFilters {
                            viewModel.activeFilterValues[filter.field] = false
                        }
                        viewModel.selectedTags.removeAll()
                        
                        // Refresh and dismiss
                        viewModel.fetchListings()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: localFilters) { checkFilterResults() }
            .onChange(of: localSelectedTags) { checkFilterResults() }
            .onAppear { checkFilterResults() }
        }
    }
    
    // Add this function to check if filters would yield results
    private func checkFilterResults() {
        // Only check if there are actual filters applied
        let hasFilters = localSelectedTags.count > 0 || localFilters.values.contains(true)
        
        if hasFilters {
            isCheckingResults = true
            // Use a background thread to not block the UI
            DispatchQueue.global(qos: .userInitiated).async {
                let hasResults = viewModel.wouldFiltersYieldResults(tags: localSelectedTags, amenities: localFilters)
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.wouldYieldResults = hasResults
                    self.isCheckingResults = false
                }
            }
        } else {
            // If no filters, we'll definitely have results
            wouldYieldResults = true
            isCheckingResults = false
        }
    }
    
    // Helper to create a consistent tag toggle row
    private func tagToggleRow(tag: String, isSelected: Bool, onToggle: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(tag.capitalized)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 2) // Reduce minimum spacing to bring toggle closer to text
            
            // Compact toggle
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .toggleStyle(CompactToggleStyle())
            .frame(width: 36) // Slightly smaller width
        }
        .padding(.trailing, 16) // Add right padding to move toggles away from divider
    }
    
    // Helper to create a consistent amenity toggle row
    private func amenityToggleRow(filter: ListingsViewModel.FilterOption, isSelected: Bool, onToggle: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(filter.displayName)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 2) // Reduce minimum spacing to bring toggle closer to text
            
            // Compact toggle
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .toggleStyle(CompactToggleStyle())
            .frame(width: 36) // Slightly smaller width
        }
        .padding(.trailing, 16) // Add right padding to move toggles away from divider
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
