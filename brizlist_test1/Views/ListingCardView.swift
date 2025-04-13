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
            // Simple white card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(listing.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Amenity symbols
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
                        
                        if listing.isBrizPick ?? false {
                            ListingStyling.brizPickStar()
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
                
                // Footer with rating, type and edit button
                HStack {
                    
                // Category
                ListingStyling.categoryTextView(listing.category)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ListingStyling.locationTextView(listing.location)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Edit button
                    Button(action: {
                        onEdit(listing)
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.caption)
                            .foregroundColor(.gray)
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
