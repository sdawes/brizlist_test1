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
            // White card
            ZStack {
                // White background
                Color.white
                    .cornerRadius(12)
                
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Category name at top left (replacing listing name)
                        Text(listing.category.uppercased())
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.black)
                        Spacer()
                        
                        // Other amenity symbols at top right
                        HStack(spacing: 4) {
                            // Briz Pick star
                            if listing.isBrizPick ?? false {
                                ListingStyling.brizPickCustomSymbol()
                            }
                            
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
                    
                    // Divider line (kept as is)
                    Divider()
                        .padding(.top, 2)
                        .padding(.bottom, 4)

                    // Listing name now below the divider
                    Text(listing.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.bottom, 2)
                    
                    // Description (kept below listing name)
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                    
                    // Footer with location and action buttons
                    HStack {
                        // Location in bottom left (kept as is)
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle.fill")
                                .font(.caption2)
                                .foregroundColor(Color.black)
                                
                            Text(listing.location.uppercased())
                                .font(.caption2)
                                .foregroundColor(Color.black)
                        }
                        
                        Spacer()
                        
                        // Edit and delete buttons
                        Button(action: {
                            onEdit(listing)
                        }) {
                            Image(systemName: "pencil.circle")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

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
