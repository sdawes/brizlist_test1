//
//  ListingCardView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI

/// A unified card view component that displays listings in different styles based on their cardState
/// - Supports "default", "new", and "featured" states
/// - Adapts layout and styling based on the cardState
/// - Maintains consistent tag formatting across all states
struct ListingCardView: View {
    let listing: Listing
    @State private var showingDetailView = false
    @State private var tagsHeight: CGFloat = 0
    
    // MARK: - Card Dimensions
    
    // Standard card height for default and new states
    private let standardHeight: CGFloat = 200
    // Featured card height (taller to accommodate the large image)
    private let featuredHeight: CGFloat = 320
    
    // MARK: - Computed Properties
    
    // Check if this is a featured card
    private var isFeatured: Bool {
        return listing.cardState == "featured"
    }
    
    // Check if this is a new listing
    private var isNewListing: Bool {
        return listing.cardState == "new"
    }
    
    // MARK: - Tag Layout System
    
    // Wrapping layout for tags with dynamic height detection
    private var wrappingTagsView: some View {
        GeometryReader { geometry in
            self.generateTagsContent(in: geometry)
                .background(
                    GeometryReader { heightGeometry -> Color in
                        let height = heightGeometry.size.height
                        DispatchQueue.main.async {
                            if height > 0 {
                                self.tagsHeight = height
                            }
                        }
                        return Color.clear
                    }
                )
        }
    }
    
    // Generate flowing, wrapping tags content that handles all three tag types
    private func generateTagsContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        // Combine all three tag types with their type identifiers
        let allTags: [(String, Int)] = 
            listing.tags1.map { ($0, 1) } + // Primary tags (cream)
            listing.tags2.map { ($0, 2) } + // Secondary tags (grey)
            listing.tags3.map { ($0, 3) }   // Tertiary tags (purple)
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(allTags.enumerated()), id: \.offset) { index, tagInfo in
                let tag = tagInfo.0
                let tagType = tagInfo.1
                
                // Select the appropriate tag style based on tag type
                Group {
                    if tagType == 1 {
                        // Primary tags (cream background)
                        ListingStyling.tagPill(tag)
                    } else if tagType == 2 {
                        // Secondary tags (light grey background)
                        ListingStyling.greyTagPill(tag)
                    } else {
                        // Tertiary tags (light purple background)
                        ListingStyling.purpleTagPill(tag)
                    }
                }
                .padding([.trailing, .bottom], 2)
                // Complex alignment guide logic to handle wrapping
                .alignmentGuide(.leading) { d in
                    if (abs(width - d.width) > g.size.width) {
                        width = 0
                        height -= d.height
                    }
                    let result = width
                    if index == allTags.count - 1 {
                        width = 0 // last item
                    } else {
                        width -= d.width
                    }
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if index == allTags.count - 1 {
                        height = 0 // last item
                    }
                    return result
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Status label for NEW listings
    private func newStatusLabel() -> some View {
        return Text("NEW")
            .font(.system(size: 10))
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 2.5)
            .padding(.horizontal, 7)
            .background(
                Rectangle()
                    .fill(Color.green.opacity(0.3))
            )
    }
    
    // MARK: - Card Design Functions
    
    // Standard card design (used for both default and new states)
    private func standardCardDesign() -> some View {
        VStack(spacing: 0) {
            // Top section - name, description, location and image
            ZStack {
                // Main content area
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    .frame(height: 16) // Space above the name
                    
                    // Name row with inline status labels
                    HStack(spacing: 6) {
                        // Listing name
                        Text(listing.name)
                            .font(isFeatured ? .title3 : .headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        // Inline status label (NEW only)
                        if isNewListing {
                            newStatusLabel()
                        }
                        
                        Spacer()
                    }
                    .padding(.trailing, 140) // Keep space for the image
                    
                    // Description (if available)
                    if !listing.shortDescription.isEmpty {
                        Text(listing.shortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(6) // Limit to 6 lines
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: UIScreen.main.bounds.width * 0.50, alignment: .leading)
                            .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 16) // Ensure minimum spacing

                    // Footer with location
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption2)
                        
                        Text(listing.location.uppercased())
                            .font(.caption2)
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                    
                    Spacer()
                    .frame(height: 16) // Space below the location
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                // Floating image on the right side
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.vertical, 16) // Equal padding above and below the image
            }
            .frame(minHeight: standardHeight * 0.75, alignment: .center) // 75% height, allows expansion with center alignment
            .background(Color.white)
            
            // Bottom section - tags with wrapping
            tagsSection()
        }
        .frame(minHeight: standardHeight)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Featured card design (larger with top image)
    private func featuredCardDesign() -> some View {
        VStack(spacing: 0) {
            // Top section - image, name, description, location
            VStack(spacing: 0) {
                // Image at the top - covers full width
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: featuredHeight / 2)  // Increased from 2.5 to 2 (50% of card height)
                    .clipShape(Rectangle())
                
                // Content section below image
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    .frame(height: 16) // Space above the name
                    
                    // Listing name
                    HStack(spacing: 6) {
                        Text(listing.name)
                            .font(isFeatured ? .title3 : .headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        // Inline status label (NEW only)
                        if isNewListing {
                            newStatusLabel()
                        }
                        
                        Spacer()
                    }
                    
                    // Description section
                    if !listing.shortDescription.isEmpty {
                        Text(listing.shortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(6) // Limit to 6 lines
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 8) // Reduced spacing between description and location
                    
                    // Footer with location
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption2)
                        
                        Text(listing.location.uppercased())
                            .font(.caption2)
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                    
                    Spacer()
                    .frame(height: 12) // Reduced space below the location
                }
                .padding(.horizontal, 12)
            }
            .frame(minHeight: featuredHeight * 0.85) // 85% height, allows expansion
            .background(Color.white)
            
            // Bottom section - tags with wrapping
            tagsSection()
        }
        .frame(minHeight: featuredHeight)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Shared tags section used by both card styles
    private func tagsSection() -> some View {
        VStack(spacing: 0) {
            // Tags row - containing all tag types flowing with wrapping
            if !listing.tags1.isEmpty || !listing.tags2.isEmpty || !listing.tags3.isEmpty {
                wrappingTagsView
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8) // Reduced from 12 to 8
                    .frame(height: tagsHeight > 0 ? tagsHeight + 16 : 30) // Reduced padding addition from 24 to 16, min height from 40 to 30
            } else {
                // Empty spacer if no tags
                Spacer().frame(height: 30) // Reduced from 40 to 30
            }
        }
        .padding(.horizontal, 12)
        .background(Color(.systemGray6)) // Light gray background
    }
    
    // MARK: - Main Body
    
    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            // Choose card design based on cardState
            // Use featured design for both featured and new listings
            if isFeatured || isNewListing {
                featuredCardDesign()
            } else {
                standardCardDesign()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetailView) {
            NavigationView {
                ListingDetailView(listing: listing)
            }
            .presentationDragIndicator(.visible)
        }
    }
}
