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
    @State private var selectedTags2: Set<String> = []
    @State private var selectedTags3: Set<String> = []
    
    // Track selected card states for filtering
    @State private var selectedCardStates: Set<String> = []
    
    // Available card states
    private let availableCardStates = ["new", "featured"]
    
    // Apply all selected filters
    private func applyFilters() {
        // Update the viewModel's selected tags
        viewModel.clearTags1()
        viewModel.clearTags2()
        viewModel.clearTags3()
        viewModel.clearCardStates()
        
        // Apply selected tags1
        for tag in selectedTags1 {
            viewModel.selectTag1(tag)
        }
        
        // Apply selected tags2
        for tag in selectedTags2 {
            viewModel.selectTag2(tag)
        }
        
        // Apply selected tags3
        for tag in selectedTags3 {
            viewModel.selectTag3(tag)
        }
        
        // Apply selected card states
        for cardState in selectedCardStates {
            viewModel.selectCardState(cardState)
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
    
    // Get all available tags1 (primary tags)
    private var allAvailableTags1: [String] {
        let tags1 = viewModel.getAllUniqueTags1()
        let cachedTags1 = viewModel.getCachedTags1()
        
        // Return both current tags1 and those from cache
        return Array(Set(tags1 + cachedTags1)).sorted()
    }
    
    // Get all available tags2 (secondary tags)
    private var allAvailableTags2: [String] {
        let tags2 = viewModel.getAllUniqueTags2()
        let cachedTags2 = viewModel.getCachedTags2()
        
        // Return both current tags2 and those from cache
        return Array(Set(tags2 + cachedTags2)).sorted()
    }
    
    // Get all available tags3 (tertiary tags)
    private var allAvailableTags3: [String] {
        let tags3 = viewModel.getAllUniqueTags3()
        let cachedTags3 = viewModel.getCachedTags3()
        
        // Return both current tags3 and those from cache
        return Array(Set(tags3 + cachedTags3)).sorted()
    }
    
    // Toggle selection of a tag1 (only changes local state, doesn't apply filter yet)
    private func toggleTag1(_ tag: String) {
        if selectedTags1.contains(tag) {
            selectedTags1.remove(tag)
        } else {
            selectedTags1.insert(tag)
        }
        // Hide any previous warning when changing selection
        showNoResultsWarning = false
    }
    
    // Toggle selection of a tag2 (only changes local state, doesn't apply filter yet)
    private func toggleTag2(_ tag: String) {
        if selectedTags2.contains(tag) {
            selectedTags2.remove(tag)
        } else {
            selectedTags2.insert(tag)
        }
        // Hide any previous warning when changing selection
        showNoResultsWarning = false
    }
    
    // Toggle selection of a tag3 (only changes local state, doesn't apply filter yet)
    private func toggleTag3(_ tag: String) {
        if selectedTags3.contains(tag) {
            selectedTags3.remove(tag)
        } else {
            selectedTags3.insert(tag)
        }
        // Hide any previous warning when changing selection
        showNoResultsWarning = false
    }
    
    // Toggle selection of a card state (only changes local state, doesn't apply filter yet)
    private func toggleCardState(_ cardState: String) {
        if selectedCardStates.contains(cardState) {
            selectedCardStates.remove(cardState)
        } else {
            selectedCardStates.insert(cardState)
        }
        // Hide any previous warning when changing selection
        showNoResultsWarning = false
    }
    
    // Get color for card state
    private func colorForCardState(_ cardState: String) -> Color {
        switch cardState.lowercased() {
        case "new":
            return Color.green.opacity(0.3)
        case "featured":
            return Color.blue.opacity(0.3)
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    // Reset all filters
    private func resetAllFilters() {
        // Clear tag selections in local state
        selectedTags1.removeAll()
        selectedTags2.removeAll()
        selectedTags3.removeAll()
        selectedCardStates.removeAll()
        
        // Reset all filters in the viewModel
        viewModel.clearAllFilters()
        
        // Reset UI warning
        showNoResultsWarning = false
    }
    
    var body: some View {
        NavigationStack {
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
                    VStack(alignment: .leading, spacing: 16) {
                        // Removed instructional text
                        
                        // Card state filter section (NEW and FEATURED)
                        VStack(alignment: .leading, spacing: 6) {
                            // Removed top Divider
                            
                            // Adding top padding instead of spacer
                            Spacer()
                                .frame(height: 12)
                            
                            HStack(spacing: 6) {
                                ForEach(availableCardStates, id: \.self) { cardState in
                                    Button(action: {
                                        toggleCardState(cardState)
                                    }) {
                                        Text(cardState.uppercased())
                                            .font(.system(size: 12))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(
                                                Rectangle()
                                                    .fill(colorForCardState(cardState))
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(selectedCardStates.contains(cardState) ? 
                                                                Color(red: 0.8, green: 0.2, blue: 0.2) : Color.clear,
                                                                lineWidth: 1.5)
                                                    )
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        if allAvailableTags1.isEmpty && allAvailableTags2.isEmpty && allAvailableTags3.isEmpty {
                            Text("No tags available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            // Section 1: Primary tags (cream colored)
                            if !allAvailableTags1.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Divider()
                                        .padding(.horizontal)
                                    
                                    // Add more vertical space (12pts) after the divider
                                    Spacer()
                                        .frame(height: 12)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(allAvailableTags1, id: \.self) { tag in
                                            Button(action: {
                                                toggleTag1(tag)
                                            }) {
                                                Text(tag.uppercased())
                                                    .font(.system(size: 12))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.black)
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 10)
                                                    .background(
                                                        Rectangle()
                                                            .fill(Color(red: 0.93, green: 0.87, blue: 0.76))
                                                            .overlay(
                                                                Rectangle()
                                                                    .stroke(selectedTags1.contains(tag) ? 
                                                                        Color(red: 0.8, green: 0.2, blue: 0.2) : Color.clear,
                                                                        lineWidth: 1.5)
                                                            )
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Section 2: Secondary tags (grey colored)
                            if !allAvailableTags2.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Divider()
                                        .padding(.horizontal)
                                    
                                    // Add more vertical space (12pts) after the divider
                                    Spacer()
                                        .frame(height: 12)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(allAvailableTags2, id: \.self) { tag in
                                            Button(action: {
                                                toggleTag2(tag)
                                            }) {
                                                Text(tag.uppercased())
                                                    .font(.system(size: 12))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.black)
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 10)
                                                    .background(
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.2))
                                                            .overlay(
                                                                Rectangle()
                                                                    .stroke(selectedTags2.contains(tag) ? 
                                                                        Color(red: 0.8, green: 0.2, blue: 0.2) : Color.clear,
                                                                        lineWidth: 1.5)
                                                            )
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Section 3: Tertiary tags (purple colored)
                            if !allAvailableTags3.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Divider()
                                        .padding(.horizontal)
                                    
                                    // Add more vertical space (12pts) after the divider
                                    Spacer()
                                        .frame(height: 12)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(allAvailableTags3, id: \.self) { tag in
                                            Button(action: {
                                                toggleTag3(tag)
                                            }) {
                                                Text(tag.uppercased())
                                                    .font(.system(size: 12))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.black)
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 10)
                                                    .background(
                                                        Rectangle()
                                                            .fill(Color.purple.opacity(0.15))
                                                            .overlay(
                                                                Rectangle()
                                                                    .stroke(selectedTags3.contains(tag) ? 
                                                                        Color(red: 0.8, green: 0.2, blue: 0.2) : Color.clear,
                                                                        lineWidth: 1.5)
                                                            )
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                // Apply button at the bottom using ListingStyling
                ListingStyling.applyButton(title: "Apply Filters", action: applyFilters)
                    .padding(.bottom)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // X button moved to the left, with light blue-gray color
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(Color.blue.opacity(0.4))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 28, height: 28)
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // "Clear Filters" button replaced with custom diagonal line
                    Button(action: {
                        resetAllFilters()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 28, height: 28)
                            
                            // Simple diagonal line
                            Rectangle()
                                .fill(Color.blue.opacity(0.4))
                                .frame(width: 16, height: 1.5)
                                .rotationEffect(Angle(degrees: -45))
                        }
                        .padding(6)
                    }
                }
            }
            .onAppear {
                // Initialize selected tags from viewModel to show current filter state
                selectedTags1 = Set(viewModel.selectedTags1)
                selectedTags2 = Set(viewModel.selectedTags2)
                selectedTags3 = Set(viewModel.selectedTags3)
                selectedCardStates = Set(viewModel.selectedCardStates)
                
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
