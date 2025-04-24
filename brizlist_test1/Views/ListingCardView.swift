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
    
    var body: some View {
        Button(action: {
            showingDetailView = true
            // Print image URL for debugging
            if let imageUrl = listing.imageUrl {
                print("📱 Listing Card for \(listing.name) has imageUrl: \(imageUrl)")
            }
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
                .padding(.top, 40) // Space for the tags row above
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Tags and cuisine row - positioned at the very top
                HStack {
                    // Only show tags if available
                    if !listing.tags.isEmpty {
                        ListingStyling.tagsView(tags: listing.tags)
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
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1)
                
                // Floating image box - vertically centered
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.trailing, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .zIndex(2)
                    .onAppear {
                        if let imageUrl = listing.imageUrl {
                            print("👁️ Card image URL for \(listing.name): \(imageUrl)")
                        } else {
                            print("⚠️ No image URL for \(listing.name)")
                        }
                    }
            }
            .frame(height: 160)
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
