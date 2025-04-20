//
//  ListingCardView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    let onEdit: (Listing) -> Void
    let onDelete: (Listing) -> Void
    @State private var showingDetailView = false
    
    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            // Card structure with full-height symbol margin
            HStack(alignment: .top, spacing: 0) {
                // Symbol margin - full height vertical column of symbols
                VStack(alignment: .center, spacing: 8) {
                    // Stack symbols vertically from top down, starting immediately
                    if listing.isFeatured ?? false { 
                        ListingStyling.featuredSymbol() 
                    }
                    if listing.isBrizPick ?? false { 
                        ListingStyling.brizPickCustomSymbol() 
                    }
                    if listing.isVeg ?? false { 
                        ListingStyling.vegSymbol() 
                    }
                    if listing.isDog ?? false { 
                        ListingStyling.dogSymbol() 
                    }
                    if listing.isChild ?? false { 
                        ListingStyling.childSymbol() 
                    }
                    if listing.isSundayLunch ?? false { 
                        ListingStyling.sundayLunchSymbol() 
                    }
                    
                    Spacer(minLength: 0) // Fill remaining space
                }
                .padding(.top, 12)
                .frame(width: UIScreen.main.bounds.width * 0.08)
                .background(Color.black) // Black background for symbol margin
                
                // Main content area
                VStack(alignment: .leading, spacing: 4) {
                    // Category and cuisine with precise padding to match symbols
                    HStack(spacing: 4) {
                        ListingStyling.categoryPill(listing.category)
                        
                        // Only show cuisine if it's not empty
                        if !listing.cuisine.isEmpty {
                            Text(listing.cuisine)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 12) // Exact match with symbol column padding
                    
                    // Listing name
                    Text(listing.name)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    // Description (if available)
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                    
                    // Footer
                    HStack {
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle.fill")
                                .font(.caption2)
                            
                            Text(listing.location.uppercased())
                                .font(.caption2)
                        }
                        .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: { onEdit(listing) }) {
                                Image(systemName: "pencil.circle")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: { onDelete(listing) }) {
                                Image(systemName: "trash.circle")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding([.trailing, .bottom], 12)
                .padding(.leading, 8)
            }
            .frame(height: 160)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: { onEdit(listing) }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: { onDelete(listing) }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDetailView) {
            NavigationView {
                ListingDetailView(listing: listing)
            }
            .presentationDragIndicator(.visible)
        }
    }
}
