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
        
        // Combine tags1 and tags2
        let allTags: [(String, Bool)] = listing.tags1.map { ($0, false) } + listing.tags2.map { ($0, true) }
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(allTags.enumerated()), id: \.offset) { index, tagInfo in
                let tag = tagInfo.0
                let isSecondary = tagInfo.1
                
                Group {
                    if isSecondary {
                        ListingStyling.greyTagPill(tag)
                    } else {
                        ListingStyling.tagPill(tag)
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
            // Card structure
            VStack(spacing: 0) {
                // Top image section - covers full width, ~half height
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: minFeaturedHeight / 2)
                    .clipShape(Rectangle())
                
                // Bottom content section
                VStack(alignment: .leading, spacing: 4) {
                    // Listing name - matched to ListingCardView style
                    Text(listing.name)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    // Tags row - containing both tags1 and tags2 flowing with wrapping
                    if !listing.tags1.isEmpty || !listing.tags2.isEmpty {
                        wrappingTagsView
                            .frame(height: tagsHeight > 0 ? tagsHeight : (listing.tags1.isEmpty && listing.tags2.isEmpty ? 0 : 30))
                            .padding(.top, 8)
                    }
                    
                    // Description section - matched to ListingCardView style
                    if !listing.shortDescription.isEmpty {
                        Text(listing.shortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Footer with location on the left
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption2)
                        
                        Text(listing.location.uppercased())
                            .font(.caption2)
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                }
                .padding(12)
            }
            .frame(minHeight: minFeaturedHeight)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                // Add badge in the top-right corner (NEW or FEATURED)
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