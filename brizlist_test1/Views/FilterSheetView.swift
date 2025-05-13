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
    
    // Track selected tags for each category (local state)
    @State private var selectedTags1: Set<String> = []
    // Keep these for future expansion
    @State private var selectedTags2: Set<String> = []
    @State private var selectedTags3: Set<String> = []
    
    // Apply all selected filters
    private func applyFilters() {
        // Update the viewModel's selected tags
        viewModel.clearTags1()
        
        // Apply selected tags
        for tag in selectedTags1 {
            viewModel.selectTag1(tag)
        }
        
        // Fetch filtered listings but don't dismiss the sheet yet
        viewModel.fetchListings()
        
        // Check if current filter selections yield no results
        // We'll use a small delay to ensure the viewModel has updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if viewModel.noResultsFromFiltering {
                // Show the warning in this view
                showNoResultsWarning = true
            } else {
                // Only dismiss if we have results
                dismiss()
            }
        }
    }
    
    // Get all available tags1 (for first section)
    private var allAvailableTags1: [String] {
        let tags1 = viewModel.getAllUniqueTags1()
        let cachedTags1 = viewModel.getCachedTags1()
        
        // Return both current tags1 and those from cache
        return Array(Set(tags1 + cachedTags1)).sorted()
    }
    
    // For future expansion - commented out for now
    /*
    // Get all available tags2 (for second section)
    private var allAvailableTags2: [String] {
        let tags2 = viewModel.getAllUniqueTags2()
        let cachedTags2 = viewModel.getCachedTags2()
        
        // Return both current tags2 and those from cache
        return Array(Set(tags2 + cachedTags2)).sorted()
    }
    
    // Get all available tags3 (for third section)
    private var allAvailableTags3: [String] {
        let tags3 = viewModel.getAllUniqueTags3()
        let cachedTags3 = viewModel.getCachedTags3()
        
        // Return both current tags3 and those from cache
        return Array(Set(tags3 + cachedTags3)).sorted()
    }
    */
    
    // Toggle selection of a tag (only changes local state, doesn't apply filter yet)
    private func toggleTag(_ tag: String, in tagSet: inout Set<String>) {
        if tagSet.contains(tag) {
            tagSet.remove(tag)
        } else {
            tagSet.insert(tag)
        }
        // No longer applying filters immediately
    }
    
    // Reset all filters
    private func resetAllFilters() {
        // Clear tag selections in local state
        selectedTags1.removeAll()
        // Keep for future expansion
        selectedTags2.removeAll()
        selectedTags3.removeAll()
        
        // Reset all filters in the viewModel
        viewModel.clearAllFilters()
        
        // Reset UI warning
        showNoResultsWarning = false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // No results warning banner in standard iOS style
                if showNoResultsWarning {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("No results found with these filters")
                                .font(.subheadline)
                                .foregroundColor(.red)
                            Spacer()
                            Button(action: {
                                showNoResultsWarning = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Tags1 Section - Primary tags (cream)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Filter by tag")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if allAvailableTags1.isEmpty {
                                Text("No tags available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            } else {
                                FlowLayout(spacing: 8) {
                                    ForEach(allAvailableTags1, id: \.self) { tag in
                                        // Use the same tag pill style but with tap gesture
                                        Button(action: {
                                            toggleTag(tag, in: &selectedTags1)
                                            // Hide any previous warning when changing selection
                                            showNoResultsWarning = false
                                        }) {
                                            Text(tag.uppercased())
                                                .font(.system(size: 12))
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    Rectangle()
                                                        .fill(selectedTags1.contains(tag) 
                                                            ? Color(red: 0.93, green: 0.87, blue: 0.76) // Selected: Original cream color
                                                            : Color(red: 0.93, green: 0.87, blue: 0.76).opacity(0.4)) // Unselected: Faded
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        /* Commented out for now - will implement in future
                        // Tags2 Section - Secondary tags (grey)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Secondary Tags")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if allAvailableTags2.isEmpty {
                                Text("No secondary tags available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            } else {
                                FlowLayout(spacing: 8) {
                                    ForEach(allAvailableTags2, id: \.self) { tag in
                                        Button(action: {
                                            toggleTag(tag, in: &selectedTags2)
                                        }) {
                                            Text(tag.uppercased())
                                                .font(.system(size: 12))
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    Rectangle()
                                                        .fill(selectedTags2.contains(tag) 
                                                            ? Color.gray.opacity(0.2) // Selected: Original grey color
                                                            : Color.gray.opacity(0.1)) // Unselected: Faded
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        */
                    }
                    .padding(.vertical, 20)
                }
                
                // Apply button at the bottom using ListingStyling
                ListingStyling.applyButton(title: "Apply Filters", action: applyFilters)
                    .padding(.bottom)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ListingStyling.resetButton {
                        resetAllFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ListingStyling.closeButton {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize selected tags from viewModel to show current filter state
                selectedTags1 = Set(viewModel.selectedTags1)
                // Keep for future expansion
                selectedTags2 = viewModel.selectedTags2
                selectedTags3 = viewModel.selectedTags3
                
                // Reset warning state when view appears
                showNoResultsWarning = false
            }
            .animation(.default, value: showNoResultsWarning)
        }
    }
}

// FlowLayout for wrapping tags similar to ListingCardView
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for row in rows {
            if let lastView = row.last {
                let rowHeight = lastView.sizeThatFits(.unspecified).height
                height += rowHeight + spacing
            }
        }
        
        return CGSize(width: width, height: max(0, height - spacing))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            
            for view in row {
                let viewSize = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height))
                x += viewSize.width + spacing
            }
            
            if let lastView = row.last {
                let lastViewSize = lastView.sizeThatFits(.unspecified)
                y += lastViewSize.height + spacing
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentRow: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if currentX + viewSize.width > width {
                rows.append(currentRow)
                currentRow = []
                currentX = 0
            }
            
            currentRow.append(view)
            currentX += viewSize.width + spacing
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}
