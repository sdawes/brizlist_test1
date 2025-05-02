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
    @State private var showNoResultsWarning = false
    
    // Known incompatible combinations - hard-coded for performance
    private let typeFilterExclusions: [String: [String]] = [
        "bar": ["isFeatured"],
        "kitchen": ["isFeatured"]
    ]
    
    private let otherFilterExclusions: [String: [String]] = [
        "isFeatured": ["bar", "kitchen"]
    ]
    
    // Helper function to create a binding for type filters
    private func createTypeFilterBinding(_ filter: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedTypeFilters.contains(filter) },
            set: { isSelected in
                if isSelected {
                    viewModel.selectTypeFilter(filter)
                } else {
                    viewModel.deselectTypeFilter(filter)
                }
                // Check if current filter selections would yield results
                checkForResults()
            }
        )
    }
    
    // Helper function to create a binding for other filters
    private func createOtherFilterBinding(_ field: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.activeFilterValues[field] ?? false },
            set: { newValue in
                viewModel.activeFilterValues[field] = newValue
                viewModel.fetchListings()
                // Check if current filter selections would yield results
                checkForResults()
            }
        )
    }
    
    // Get all available type filters (for "Filter by Type" section)
    private var allAvailableTypeFilters: [String] {
        let typeFilters = viewModel.getAllUniqueTypeFilters()
        let cachedTypeFilters = viewModel.getCachedTypeFilters()
        
        // Return both current type filters and those from cache
        return Array(Set(typeFilters + cachedTypeFilters))
            .filter { !$0.lowercased().contains("tag") }
            .sorted()
    }
    
    // Get all available tag filters (for "Filter by Categories" section)
    private var allAvailableTags: [String] {
        let tags = viewModel.getAllUniqueTags()
        let cachedTags = viewModel.getCachedTags()
        
        // Return both current tags and those from cache
        return Array(Set(tags + cachedTags)).sorted()
    }
    
    // Check if a type filter is compatible with currently selected Other Filters
    private func isTypeFilterCompatible(_ filter: String) -> Bool {
        // If already selected, it's compatible
        if viewModel.selectedTypeFilters.contains(filter) {
            return true
        }
        
        // Check for hard-coded incompatibilities
        for (otherFilter, incompatibleTypes) in otherFilterExclusions {
            if viewModel.activeFilterValues[otherFilter] == true && incompatibleTypes.contains(filter) {
                return false
            }
        }
        
        return true
    }
    
    // Check if an other filter is compatible with currently selected Type Filters
    private func isOtherFilterCompatible(_ field: String) -> Bool {
        // If already selected, it's compatible
        if viewModel.activeFilterValues[field] == true {
            return true
        }
        
        // Check for hard-coded incompatibilities
        if let incompatibleTypes = typeFilterExclusions[field] {
            for type in incompatibleTypes {
                if viewModel.selectedTypeFilters.contains(type) {
                    return false
                }
            }
        }
        
        return true
    }
    
    // Check if the current filter combination would yield results
    private func checkForResults() {
        // Use a slight delay to ensure filters have been applied
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showNoResultsWarning = viewModel.noResultsFromFiltering
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Warning message when filter combination would yield no results
                if showNoResultsWarning {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("This filter combination yields no results")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                List {
                    // Type Filters Section - at the top
                    Section(header: Text("Filter by Type")) {
                        ForEach(allAvailableTypeFilters, id: \.self) { filter in
                            Toggle(filter.capitalized, isOn: createTypeFilterBinding(filter))
                        }
                    }
                    
                    // Tags Section - in the middle
                    Section(header: Text("Filter by Categories")) {
                        ForEach(allAvailableTags, id: \.self) { tag in
                            Toggle(tag.capitalized, isOn: createTypeFilterBinding(tag))
                        }
                    }
                    
                    // Other Filters Section - at the bottom
                    Section(header: Text("Other Filters")) {
                        ForEach(viewModel.availableFilters, id: \.field) { filter in
                            Toggle(filter.displayName, isOn: createOtherFilterBinding(filter.field))
                        }
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
                        viewModel.clearTypeFilters()
                        viewModel.fetchListings()
                        showNoResultsWarning = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Check initial filter state
                checkForResults()
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
