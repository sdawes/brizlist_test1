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
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

    // MARK: - Amenity Symbols
    
    static func veganSymbol() -> some View {
        Image(systemName: "carrot.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }
    
    static func vegSymbol() -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }
    
    static func dogSymbol() -> some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }
    
    static func childSymbol() -> some View {
        Image(systemName: "figure.2.and.child.holdinghands")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

    // MARK: - Sunday Lunch Symbol
    
    static func sundayLunchSymbol() -> some View {
        Image(systemName: "oven.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

    

    // MARK: - Category Pill

    static func categoryPill(_ category: String) -> some View {
        let systemName: String
        let color: Color
        
        switch category.lowercased() {
        case "pub", "bar":
            systemName = "mug.fill"
            color = Color(red: 0.13, green: 0.55, blue: 0.13) // Deep forest green
        case "restaurant", "bistro":
            systemName = "fork.knife"
            color = Color(red: 0.75, green: 0.0, blue: 0.0) // Deep crimson red
        case "café", "cafe", "coffee shop":
            systemName = "cup.and.saucer.fill"
            color = Color(red: 0.0, green: 0.35, blue: 0.65) // Rich navy blue
        case "bakery":
            systemName = "birthday.cake.fill"
            color = Color(red: 0.65, green: 0.16, blue: 0.43) // Deep magenta
        case "deli", "food market":
            systemName = "basket.fill"
            color = Color(red: 0.55, green: 0.27, blue: 0.07) // Rich brown
        case "takeaway", "fast food":
            systemName = "bag.fill"
            color = Color(red: 0.85, green: 0.53, blue: 0.0) // Deep amber/orange
        default:
            systemName = "mappin"
            color = Color(red: 0.35, green: 0.35, blue: 0.35) // Dark charcoal
        }
        
        return HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.caption2)
            
            Text(category.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(color)
        )
    }

    // MARK: - Featured Symbol
    static func featuredSymbol() -> some View {
        Image(systemName: "medal.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

}
