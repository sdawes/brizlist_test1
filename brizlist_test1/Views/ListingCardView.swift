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
    
    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            // Card structure without symbol margin
            ZStack(alignment: .top) {
                // Main content area
                VStack(alignment: .leading, spacing: 4) {
                    // Listing name first (moved to top)
                    Text(listing.name)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    // Tags and cuisine row - now placed below the name
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .zIndex(2)
            }
            .frame(height: standardHeight)
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
