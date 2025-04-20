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
            // Card structure without symbol margin
            ZStack(alignment: .top) {
                // Main content area excluding category (starts below the category)
                VStack(alignment: .leading, spacing: 4) {
                    // Listing name
                    Text(listing.name)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    // Description (if available)
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3) // Allow up to 3 lines
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                            .frame(width: UIScreen.main.bounds.width * 0.45, alignment: .leading)
                            .padding(.top, 2)
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
                .padding(.bottom, 12)
                .padding(.top, 40) // Space for the category row above
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Category and cuisine row - positioned at the very top
                HStack {
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
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1)
                
                // Floating image box - aligned with category
                Image("tacos")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 12) // Same as category top padding
                    .padding(.trailing, 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .zIndex(2)
                
                // Action buttons positioned under the image
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
                .padding(.trailing, 12)
                .padding(.top, 137) // Position below the image (image height 120 + top padding 12 + extra 5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .zIndex(3)
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
