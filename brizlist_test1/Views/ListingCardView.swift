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
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    // Main card content
                    VStack(alignment: .leading, spacing: 8) {
                        // Image at the top
                        if let imageURL = listing.imageUrl {
                            FirebaseStorageImage(path: imageURL)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 160, height: 160)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.largeTitle)
                                )
                        }
                        
                        // Listing details below the image
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(listing.shortDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            // Location and tags
                            HStack {
                                if !listing.location.isEmpty {
                                    Text(listing.location)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(12)
                    }
                    
                    // NEW badge if the listing is new
                    if listing.isNew == true {
                        Text("NEW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
            }
            .frame(height: standardHeight)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
