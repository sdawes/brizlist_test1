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
            // Card with category background
            ZStack(alignment: .center) {
                // Background color
                ListingStyling.colorForCategory(listing.category)
                    .cornerRadius(12)
                
                // Large category text watermark (for all categories)
                Text(listing.category.uppercased())
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.white.opacity(0.5))  // Less transparent
                    .rotationEffect(.degrees(-10))
                    .frame(maxWidth: .infinity)
                
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(listing.name)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        // Briz Pick star right next to name
                        if listing.isBrizPick ?? false {
                            ListingStyling.brizPickCustomSymbol()
                        }
                        
                        Spacer()
                        
                        // Other amenity symbols
                        HStack(spacing: 4) {
                            if listing.isVegan ?? false {
                                ListingStyling.veganSymbol()
                                    .foregroundColor(.black) 
                            }
                            if listing.isVeg ?? false {
                                ListingStyling.vegSymbol()
                                    .foregroundColor(.black)
                            }
                            if listing.isDog ?? false {
                                ListingStyling.dogSymbol()
                                    .foregroundColor(.black)
                            }
                            if listing.isChild ?? false {
                                ListingStyling.childSymbol()
                                    .foregroundColor(.black)
                            }
                            if listing.isSundayLunch ?? false {
                                ListingStyling.sundayLunchSymbol()
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    
                    // Divider line
                    Divider()
                        .padding(.top, 2)
                        .padding(.bottom, 4)

                    // Add description back
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                
                    
                    Spacer()
                    
                    // Footer with location and action buttons (category removed)
                    HStack {
                        // Only show location now
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.gray.opacity(0.7))
                                
                            Text(listing.location.uppercased())
                                .font(.caption)
                                .foregroundColor(Color.gray.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Edit button
                        Button(action: {
                            onEdit(listing)
                        }) {
                            Image(systemName: "pencil.circle")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        // Delete button
                        Button(action: {
                            onDelete(listing)
                        }) {
                            Image(systemName: "trash.circle")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .frame(height: 160)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                onEdit(listing)
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                onDelete(listing)
            }) {
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
