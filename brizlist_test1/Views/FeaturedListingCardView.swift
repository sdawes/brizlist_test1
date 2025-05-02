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
    
    // Featured card height
    private let featuredHeight: CGFloat = 320
    
    // Verify that this listing is actually featured (defensive check)
    var isFeatured: Bool {
        return listing.isFeatured ?? false
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
                    .frame(height: featuredHeight / 2)
                    .clipShape(Rectangle())
                
                // Bottom content section
                VStack(alignment: .leading, spacing: 4) {
                    // Listing name - matched to ListingCardView style
                    Text(listing.name)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    // Tags and cuisine row in a single HStack
                    HStack {
                        // Only show tags if available
                        if !listing.typeFilters.isEmpty {
                            ListingStyling.typeFiltersView(typeFilters: listing.typeFilters)
                        }
                        
                        // Only show cuisine if it's not empty
                        if !listing.cuisine.isEmpty {
                            Text(listing.cuisine)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    // Description section - matched to ListingCardView style
                    if !listing.shortDescription.isEmpty {
                        Text(listing.shortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Footer with location
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
            .frame(height: featuredHeight)
            .background(Color.white)
            .cornerRadius(12)
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