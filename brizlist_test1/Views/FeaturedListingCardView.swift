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
            ZStack(alignment: .top) {
                // Main content area excluding category (starts below the category)
                VStack(alignment: .leading, spacing: 4) {
                    // Listing name
                    Text(listing.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top, 4)
                    
                    // Description (if available)
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(6)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: UIScreen.main.bounds.width * 0.45, alignment: .leading)
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
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Tags and cuisine row
                HStack {
                    if !listing.tags.isEmpty {
                        ListingStyling.tagsView(tags: listing.tags)
                    }
                    
                    if !listing.cuisine.isEmpty {
                        Text(listing.cuisine)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1)
                
                // Large featured image
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.trailing, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .zIndex(2)
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