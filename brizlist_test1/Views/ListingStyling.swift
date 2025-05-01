//
//  ListingStyling.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 18/03/2025.
//

import Foundation
import SwiftUI

struct ListingStyling {
    

    
    

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

    // MARK: - Tag Pills

    static func tagPill(_ tag: String) -> some View {
        return Text(tag.uppercased())
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Color(red: 0.93, green: 0.87, blue: 0.76)) // Light oak cream color
            )
    }

    // Helper function for backward compatibility
    static func styleForTag(_ tag: String) -> (systemName: String, color: Color) {
        // All tags now use the same style, but keeping method for backward compatibility
        return ("", Color(red: 0.93, green: 0.87, blue: 0.76)) // Light oak cream color
    }

    // View for displaying multiple tags horizontally
    static func tagsView(tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags, id: \.self) { tag in
                    tagPill(tag)
                }
            }
        }
    }

}
