//
//  ListingDetailView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with name
                Text(listing.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Type and category pills
                HStack(spacing: 10) {
                    Text(listing.type)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorForType(listing.type))
                        .cornerRadius(8)
                    
                    Text(listing.category)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorForCategory(listing.category))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(listing.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Listing Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper functions for colors (same as in ListingCardView)
    private func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "restaurant":
            return .red
        case "cafe":
            return .orange
        case "bar":
            return .purple
        default:
            return .blue
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "premium":
            return .yellow
        case "featured":
            return .green
        default:
            return .gray
        }
    }
}
