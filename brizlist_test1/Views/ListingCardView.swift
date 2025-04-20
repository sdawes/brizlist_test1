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
            // Simple white card with direct content
            VStack(alignment: .leading, spacing: 8) {
                // Top row with category and symbols
                HStack {
                    // Category with symbol
                    HStack(spacing: 4) {
                        ListingStyling.categoryPill(listing.category)
                        
                        // Only show cuisine if it's not empty
                        if !listing.cuisine.isEmpty {
                            Text(listing.cuisine)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Amenity symbols
                    HStack(spacing: 4) {
                        if listing.isFeatured ?? false { 
                            ListingStyling.featuredSymbol() 
                        }
                        if listing.isBrizPick ?? false { 
                            ListingStyling.brizPickCustomSymbol() 
                        }
                        if listing.isVeg ?? false { ListingStyling.vegSymbol() }
                        if listing.isDog ?? false { ListingStyling.dogSymbol() }
                        if listing.isChild ?? false { ListingStyling.childSymbol() }
                        if listing.isSundayLunch ?? false { ListingStyling.sundayLunchSymbol() }
                    }
                    .foregroundColor(.black)
                }
                
                Divider()
                
                // Listing name
                Text(listing.name)
                    .font(.headline)
                
                // Description (if available)
                if !listing.description.isEmpty {
                    Text(listing.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
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
            .padding()
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
