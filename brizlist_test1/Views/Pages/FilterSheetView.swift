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
    
    // Track selected tags for each category (local state)
    @State private var selectedTags1: Set<String> = []
    @State private var selectedTags2: Set<String> = []
    @State private var selectedTags3: Set<String> = []
    @State private var selectedLocationTags: Set<String> = [] // Added for location filtering
    
    // Track selected card states for filtering
    @State private var selectedCardStyling: Set<String> = []
    
    // Available card styling options
    private let availableCardStyling = ["new", "large", "coming"]
    
    // Apply all selected filters
    private func applyFilters() {
        // Update the viewModel's selected tags
        viewModel.clearTags1()
        viewModel.clearTags2()
        viewModel.clearTags3()
        viewModel.clearCardStates()
        viewModel.clearLocationTags() // Clear location tags
        
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
        
        // Apply selected location tags
        for tag in selectedLocationTags {
            viewModel.selectLocationTag(tag)
        }
        
        // Apply selected card states
        for cardState in selectedCardStyling {
            viewModel.selectCardState(cardState)
        }
        
        // Fetch filtered listings
        viewModel.fetchListings()
        
        // Always dismiss the filter sheet - let ContentView handle the no results state
        dismiss()
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
    
    // Get all available location tags
    private var allAvailableLocationTags: [String] {
        let locationTags = viewModel.getAllUniqueLocations()
        let cachedLocationTags = viewModel.getCachedLocationTags()
        
        // Return both current location tags and those from cache
        return Array(Set(locationTags + cachedLocationTags)).sorted()
    }
    
    // Toggle selection of a tag1 (only changes local state, doesn't apply filter yet)
    private func toggleTag1(_ tag: String) {
        if selectedTags1.contains(tag) {
            selectedTags1.remove(tag)
        } else {
            selectedTags1.insert(tag)
        }
    }
    
    // Toggle selection of a tag2 (only changes local state, doesn't apply filter yet)
    private func toggleTag2(_ tag: String) {
        if selectedTags2.contains(tag) {
            selectedTags2.remove(tag)
        } else {
            selectedTags2.insert(tag)
        }
    }
    
    // Toggle selection of a tag3 (only changes local state, doesn't apply filter yet)
    private func toggleTag3(_ tag: String) {
        if selectedTags3.contains(tag) {
            selectedTags3.remove(tag)
        } else {
            selectedTags3.insert(tag)
        }
    }
    
    // Toggle selection of a card state (only changes local state, doesn't apply filter yet)
    private func toggleCardState(_ cardState: String) {
        if selectedCardStyling.contains(cardState) {
            selectedCardStyling.remove(cardState)
        } else {
            selectedCardStyling.insert(cardState)
        }
    }
    
    // Toggle selection of a location tag (only changes local state, doesn't apply filter yet)
    private func toggleLocationTag(_ tag: String) {
        if selectedLocationTags.contains(tag) {
            selectedLocationTags.remove(tag)
        } else {
            selectedLocationTags.insert(tag)
        }
    }
    
    // Get color for card state
    private func colorForCardState(_ cardState: String) -> Color {
        switch cardState.lowercased() {
        case "new":
            return Color.green.opacity(0.3)
        case "large":
            return Color(red: 0.0, green: 0.4, blue: 0.9).opacity(0.3)
        case "coming":
            return Color(red: 1.0, green: 0.9, blue: 0.0).opacity(0.3)
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    // Get color for tag1 (Type)
    private func colorForTag1(isSelected: Bool = false) -> Color {
        let baseColor = Color(red: 0.93, green: 0.87, blue: 0.76)
        return isSelected ? baseColor.opacity(0.9) : baseColor
    }
    
    // Get color for tag2 (Vibe)
    private func colorForTag2(isSelected: Bool = false) -> Color {
        let baseColor = Color.gray.opacity(0.2)
        return isSelected ? baseColor.opacity(0.5) : baseColor
    }
    
    // Get color for tag3 (Cuisine)
    private func colorForTag3(isSelected: Bool = false) -> Color {
        let baseColor = Color.purple.opacity(0.15)
        return isSelected ? baseColor.opacity(0.5) : baseColor
    }
    
    // Get color for location tag
    private func colorForLocation(isSelected: Bool = false) -> Color {
        let baseColor = Color(red: 0.75, green: 0.87, blue: 0.85)
        return isSelected ? baseColor.opacity(0.9) : baseColor
    }
    
    // Reset all filters
    private func resetAllFilters() {
        // Clear tag selections in local state
        selectedTags1.removeAll()
        selectedTags2.removeAll()
        selectedTags3.removeAll()
        selectedLocationTags.removeAll() // Clear location tags
        selectedCardStyling.removeAll()
        
        // Reset all filters in the viewModel
        viewModel.clearAllFilters()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Removed instructional text
                        
                        // Card state filter section (NEW and LARGE)
                        VStack(alignment: .leading, spacing: 6) {
                            // Removed top Divider
                            
                                            // Section title for Card Styling
                Text("CARD STYLING")
                                .font(.system(size: 13))
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            // Adding top padding instead of spacer
                            Spacer()
                                .frame(height: 8)
                            
                            HStack(spacing: 6) {
                                ForEach(availableCardStyling, id: \.self) { cardState in
                                    Button(action: {
                                        toggleCardState(cardState)
                                    }) {
                                        HStack(spacing: 4) {
                                            // Checkmark that appears when selected
                                            if selectedCardStyling.contains(cardState) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.black)
                                            }
                                            
                                            Text(cardState.uppercased())
                                                .font(.system(size: 12))
                                                // Use bold text when selected
                                                .fontWeight(selectedCardStyling.contains(cardState) ? .bold : .medium)
                                                .foregroundColor(.black)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(
                                            Rectangle()
                                                .fill(colorForCardState(cardState))
                                        )
                                        // Keep just the scale animation
                                        .scaleEffect(selectedCardStyling.contains(cardState) ? 1.03 : 1.0)
                                        // Add animation for smooth transition
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCardStyling.contains(cardState))
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
                                    // Removed Divider
                                    
                                    // Section title for Type
                                    Text("TYPE")
                                        .font(.system(size: 13))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.top, 16) // Added top padding for section separation
                                    
                                    // Add more vertical space (8pts) after the title
                                    Spacer()
                                        .frame(height: 8)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(allAvailableTags1, id: \.self) { tag in
                                            Button(action: {
                                                toggleTag1(tag)
                                            }) {
                                                HStack(spacing: 4) {
                                                    // Checkmark that appears when selected
                                                    if selectedTags1.contains(tag) {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.black)
                                                    }
                                                    
                                                    Text(tag.uppercased())
                                                        .font(.system(size: 12))
                                                        // Use bold text when selected
                                                        .fontWeight(selectedTags1.contains(tag) ? .bold : .medium)
                                                        .foregroundColor(.black)
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    Rectangle()
                                                        .fill(Color(red: 0.93, green: 0.87, blue: 0.76))
                                                )
                                                // Keep just the scale animation
                                                .scaleEffect(selectedTags1.contains(tag) ? 1.03 : 1.0)
                                                // Add animation for smooth transition
                                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTags1.contains(tag))
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
                                    // Removed Divider
                                    
                                    // Section title for Vibe
                                    Text("VIBE")
                                        .font(.system(size: 13))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.top, 16) // Added top padding for section separation
                                    
                                    // Add more vertical space (8pts) after the title
                                    Spacer()
                                        .frame(height: 8)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(allAvailableTags2, id: \.self) { tag in
                                            Button(action: {
                                                toggleTag2(tag)
                                            }) {
                                                HStack(spacing: 4) {
                                                    // Checkmark that appears when selected
                                                    if selectedTags2.contains(tag) {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.black)
                                                    }
                                                    
                                                    Text(tag.uppercased())
                                                        .font(.system(size: 12))
                                                        // Use bold text when selected
                                                        .fontWeight(selectedTags2.contains(tag) ? .bold : .medium)
                                                        .foregroundColor(.black)
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.2))
                                                )
                                                // Keep just the scale animation
                                                .scaleEffect(selectedTags2.contains(tag) ? 1.03 : 1.0)
                                                // Add animation for smooth transition
                                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTags2.contains(tag))
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
                                    // Removed Divider
                                    
                                    // Section title for Cuisine
                                    Text("CUISINE")
                                        .font(.system(size: 13))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.top, 16) // Added top padding for section separation
                                    
                                    // Add more vertical space (8pts) after the title
                                    Spacer()
                                        .frame(height: 8)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(allAvailableTags3, id: \.self) { tag in
                                            Button(action: {
                                                toggleTag3(tag)
                                            }) {
                                                HStack(spacing: 4) {
                                                    // Checkmark that appears when selected
                                                    if selectedTags3.contains(tag) {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.black)
                                                    }
                                                    
                                                    Text(tag.uppercased())
                                                        .font(.system(size: 12))
                                                        // Use bold text when selected
                                                        .fontWeight(selectedTags3.contains(tag) ? .bold : .medium)
                                                        .foregroundColor(.black)
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    Rectangle()
                                                        .fill(Color.purple.opacity(0.15))
                                                )
                                                // Keep just the scale animation
                                                .scaleEffect(selectedTags3.contains(tag) ? 1.03 : 1.0)
                                                // Add animation for smooth transition
                                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTags3.contains(tag))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Section 4: Location tags (soft teal/aqua colored)
                            if !allAvailableLocationTags.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    // Section title for Location
                                    Text("LOCATION")
                                        .font(.system(size: 13))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.top, 16) // Added top padding for section separation
                                    
                                    // Add more vertical space (8pts) after the title
                                    Spacer()
                                        .frame(height: 8)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(allAvailableLocationTags, id: \.self) { tag in
                                            Button(action: {
                                                toggleLocationTag(tag)
                                            }) {
                                                HStack(spacing: 4) {
                                                    // Checkmark that appears when selected
                                                    if selectedLocationTags.contains(tag) {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.black)
                                                    }
                                                    
                                                    Text(tag.uppercased())
                                                        .font(.system(size: 12))
                                                        // Use bold text when selected
                                                        .fontWeight(selectedLocationTags.contains(tag) ? .bold : .medium)
                                                        .foregroundColor(.black)
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    Rectangle()
                                                        .fill(Color(red: 0.75, green: 0.87, blue: 0.85))
                                                )
                                                // Keep just the scale animation
                                                .scaleEffect(selectedLocationTags.contains(tag) ? 1.03 : 1.0)
                                                // Add animation for smooth transition
                                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedLocationTags.contains(tag))
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
                            .font(.system(size: 10))
                            .foregroundColor(Color.blue.opacity(0.4))
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 24, height: 24)
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Changed from custom diagonal line to trash can
                    Button(action: {
                        resetAllFilters()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(Color.blue.opacity(0.4))
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 24, height: 24)
                            )
                    }
                }
            }
            .onAppear {
                // Initialize selected tags from viewModel to show current filter state
                selectedTags1 = Set(viewModel.selectedTags1)
                selectedTags2 = Set(viewModel.selectedTags2)
                selectedTags3 = Set(viewModel.selectedTags3)
                selectedLocationTags = Set(viewModel.selectedLocationTags) // Initialize location tags
                selectedCardStyling = Set(viewModel.selectedCardStyling)
            }
            .animation(.default, value: selectedTags1)
        }
    }
}

// FlowLayout for wrapping tags similar to the card views
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
