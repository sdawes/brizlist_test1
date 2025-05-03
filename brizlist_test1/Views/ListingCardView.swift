//
//  ListingCardView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    @State private var showingDetailView = false
    
    // Standard card height
    private let standardHeight: CGFloat = 160
    
    // Helper for checking featured status
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
            // Card structure without symbol margin
            ZStack(alignment: .top) {
                // Main content area
                VStack(alignment: .leading, spacing: 4) {
                    // Name and cuisine in the same row
                    HStack {
                        // Listing name
                        Text(listing.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Cuisine on the right side but to the left of the image
                        if !listing.cuisine.isEmpty {
                            Text(listing.cuisine)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.trailing, 140) // Increased from 124 to add more space between cuisine and image
                    
                    // Tags row - now placed below the name
                    HStack {
                        // Only show tags if available
                        if !listing.typeFilters.isEmpty {
                            ListingStyling.typeFiltersView(typeFilters: listing.typeFilters)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 140) // Keep consistent with the name/cuisine row
                    
                    // Description (if available)
                    if !listing.shortDescription.isEmpty {
                        Text(listing.shortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: UIScreen.main.bounds.width * 0.45, alignment: .leading)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Footer with just location
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption2)
                        
                        Text(listing.location.uppercased())
                            .font(.caption2)
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)  // Changed from top/bottom padding to vertical
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Floating image box - vertically centered
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.trailing, 12)
                    .padding(.top, 14) // Increased from 12 to move down 2 pixels
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .zIndex(2)
                
                // Symbols positioned vertically centered between image bottom and card bottom
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
                .padding(.bottom, 11) // Decreased from 13 to move down 2 pixels
                .zIndex(1) // Below the image but above content
            }
            .frame(height: listing.isFeatured ?? false ? standardHeight * 2 : standardHeight)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                // Add the "NEW" badge in the top-right corner for new listings
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
