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
    
    // Determine if the listing is new
    private var isNewListing: Bool {
        return listing.isNew ?? false
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
                        if !listing.tags1.isEmpty {
                            ListingStyling.tags1View(tags1: listing.tags1)
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
            .overlay(
                // Symbols positioned at the bottom right
                HStack(spacing: 6) {
                    // Star for Briz Picks
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .opacity(listing.isBrizPick ?? false ? 1.0 : 0.0)
                    
                    // Heart symbol as a second example
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .opacity(0.8) // Just for demonstration
                }
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.bottom, 11) // Same as in ListingCardView
                .zIndex(1)
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