//
//  ListingStyling.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 18/03/2025.
//

import Foundation
import SwiftUI

struct ListingStyling {
    
    // MARK: - Category Styling
    
    static func categoryTextView(_ category: String) -> some View {
        Text(category.lowercased())
            .font(.caption)
            .foregroundColor(.black)
    }
    
    

    // MARK: - Location Styling
    
    static func locationTextView(_ location: String) -> some View {
        Text(location.lowercased())
            .font(.caption)
            .foregroundColor(.black)
    }


    // MARK: - BrizPick Styling
    
    static func brizPickBadge() -> some View {
        HStack(spacing: 4) {
            // Enhanced rainbow gradient star
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Briz Pick text in black
            Text("Briz Pick")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
    }

    // MARK: - BrizPick Star Styling
    
    static func brizPickStar() -> some View {
        Image(systemName: "star.fill")
            .font(.caption)
            .foregroundColor(.red) // Standard system red
    }

    // MARK: - BrizPick Custom Symbol
    
    static func brizPickCustomSymbol() -> some View {
        Image(systemName: "star.fill")
            .font(.caption)
            .foregroundColor(.black)
    }

    // MARK: - Amenity Symbols
    
    static func veganSymbol() -> some View {
        Image(systemName: "carrot.fill")
            .font(.caption)
    }
    
    static func vegSymbol() -> some View {
        Image(systemName: "leaf.fill")
            .font(.caption)
    }
    
    static func dogSymbol() -> some View {
        Image(systemName: "pawprint.fill")
            .font(.caption)
    }
    
    static func childSymbol() -> some View {
        Image(systemName: "figure.2.and.child.holdinghands")
            .font(.caption)
    }

    // MARK: - Sunday Lunch Symbol
    
    static func sundayLunchSymbol() -> some View {
        Image(systemName: "oven.fill")
            .font(.caption)
    }

    // MARK: - CATEGORY COLORS

    static func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "pub", "bar":
            return Color(red: 0.82, green: 0.94, blue: 0.88) // #D0F0E0
        case "restaurant", "bistro":
            return Color(red: 0.95, green: 0.87, blue: 0.73) // Pastel orange/peach
        case "café", "cafe", "coffee shop":
            return Color(red: 0.87, green: 0.80, blue: 0.95) // Pastel purple
        case "bakery":
            return Color(red: 0.95, green: 0.80, blue: 0.85) // Pastel pink
        case "deli", "food market":
            return Color(red: 0.75, green: 0.87, blue: 0.95) // Pastel blue
        default:
            return Color.white // Default white for other categories
        }
    }

}
