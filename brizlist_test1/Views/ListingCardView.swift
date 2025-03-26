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
                // Name and category
                HStack {
                    // Name
                    Text(listing.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer ()

                    // Location
                    ListingStyling.categoryLocationView(listing.location)

                    // Category
                    ListingStyling.categoryTextView(listing.category)
                }

                // Divider line
                Divider()
                    .padding(.top, 2)
                    .padding(.bottom, 4)

                // Description
                if !listing.description.isEmpty {
                    Text(listing.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Footer with rating, type and edit button
                HStack {
                    
                    // Type
                    ListingStyling.typeTextView(listing.type)
                    
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
            .frame(height: 180)
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
        }
    }
}
