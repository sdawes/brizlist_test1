//
//  LargeCardView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 27/05/2025.
//

import SwiftUI

/// A card view component for large listings
/// - Displays listings in large format with full-width top image
/// - Uses the existing large card design with 320pt height
/// - Includes tag wrapping system for all three tag types
/// - Maintains consistent styling and navigation
struct LargeCardView: View {
    let listing: Listing
    @State private var showingDetailView = false
    @State private var tagsHeight: CGFloat = 0
    
    // MARK: - Card Dimensions
    
    // Large card height (taller to accommodate the large image)
    private let featuredHeight: CGFloat = 320
    
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
    
    // MARK: - Card Design
    
    // Large card design with full-width top image
    private func cardDesign() -> some View {
        VStack(spacing: 0) {
            // Top section - image, name, description, location
            VStack(spacing: 0) {
                // Image at the top - covers full width
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: featuredHeight / 2)  // 50% of card height (160pt)
                    .clipShape(Rectangle())
                
                // Content section below image
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    .frame(height: 16) // Space above the name
                    
                    // Listing name
                    HStack(spacing: 6) {
                        Text(listing.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    // Footer with location (now comes first)
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption2)
                        
                        Text(listing.location.uppercased())
                            .font(.caption2)
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                    .padding(.top, 8)
                    
                    // Description section (now comes after location)
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
                    
                    Spacer(minLength: 8) // Ensure minimum spacing at bottom
                    
                    Spacer()
                    .frame(height: 12) // Reduced space at bottom
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
    
    // Shared tags section
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
            cardDesign()
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

