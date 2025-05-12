//
//  FeaturedListingCardView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI

struct FeaturedListingCardView: View {
    let listing: Listing
    @State private var showingDetailView = false
    @State private var tagsHeight: CGFloat = 0
    
    // Featured card height - made flexible to accommodate content
    private let minFeaturedHeight: CGFloat = 320
    
    // Verify that this listing is actually featured (defensive check)
    var isFeatured: Bool {
        return listing.isFeatured ?? false
    }
    
    // Determine if the listing is new
    private var isNewListing: Bool {
        return listing.isNew ?? false
    }
    
    // Simple wrapping HStack for tags with dynamic height
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
    
    private func generateTagsContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        // Combine tags1, tags2, and tags3
        let allTags: [(String, Int)] = 
            listing.tags1.map { ($0, 1) } + 
            listing.tags2.map { ($0, 2) } + 
            listing.tags3.map { ($0, 3) }
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(allTags.enumerated()), id: \.offset) { index, tagInfo in
                let tag = tagInfo.0
                let tagType = tagInfo.1
                
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
    
    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            // New card structure with two-section design
            VStack(spacing: 0) {
                // Top section - image, name, description, location
                VStack(spacing: 0) {
                    // Image at the top - covers full width
                    FirebaseStorageImage(urlString: listing.imageUrl)
                        .frame(maxWidth: .infinity)
                        .frame(height: minFeaturedHeight / 2.5)
                        .clipShape(Rectangle())
                    
                    // Content section below image
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()
                        .frame(height: 16) // Space above the name
                        
                        // Listing name
                        Text(listing.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        // Description section
                        if !listing.shortDescription.isEmpty {
                            Text(listing.shortDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(6) // Limit to 6 lines for very long descriptions
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }
                        
                        Spacer(minLength: 16) // Use Spacer with minLength to ensure minimum spacing
                        
                        // Footer with location on the left
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
                }
                .frame(minHeight: minFeaturedHeight * 0.85) // Top section takes 85% of the height
                .background(Color.white)
                
                // Bottom section - tags with wrapping (dynamic height)
                VStack(spacing: 0) {
                    // Tags row - containing both tags1 and tags2 flowing with wrapping
                    if !listing.tags1.isEmpty || !listing.tags2.isEmpty {
                        wrappingTagsView
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12) // Consistent vertical padding
                            .frame(height: tagsHeight > 0 ? tagsHeight + 24 : 40) // Height + padding
                    } else {
                        // Empty spacer if no tags to maintain minimum height
                        Spacer().frame(height: 40)
                    }
                }
                .padding(.horizontal, 12)
                .background(Color(.systemGray6)) // Light gray background for the bottom section
            }
            .frame(minHeight: minFeaturedHeight)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                // Add badge in the top-right corner (NEW)
                ZStack {
                    if isNewListing {
                        VStack {
                            HStack {
                                Spacer()
                                Text("NEW")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
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