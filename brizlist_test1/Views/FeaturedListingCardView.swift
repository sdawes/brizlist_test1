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
                VStack(alignment: .leading, spacing: 8) {
                    // Tags row
                    HStack {
                        if !listing.tags.isEmpty {
                        ListingStyling.tagsView(tags: listing.tags)
                            .padding(.top, 8)
                    }
                    
                    // Cuisine if available
                    if !listing.cuisine.isEmpty {
                        Text(listing.cuisine)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    }
                    
                    
                    // Listing name
                    Text(listing.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top, 4)
                    
                    // Description section
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                    
                    // Footer with location
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption)
                        
                        Text(listing.location.uppercased())
                            .font(.caption)
                            .fontWeight(.medium)
                        
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