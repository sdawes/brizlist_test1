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

    // MARK: - Tag Pills

    static func tagPill(_ tag: String) -> some View {
        return Text(tag.uppercased())
            .font(.system(size: 10))
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 2.5)
            .padding(.horizontal, 7)
            .background(
                Rectangle()
                    .fill(Color(red: 0.93, green: 0.87, blue: 0.76))
            )
    }
    
    // Grey tag pill for secondary tags
    static func greyTagPill(_ tag: String) -> some View {
        return Text(tag.uppercased())
            .font(.system(size: 10))
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 2.5)
            .padding(.horizontal, 7)
            .background(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
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

    // Adding a new method with updated name for future use
    static func tags1View(tags1: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags1, id: \.self) { filter in
                    tagPill(filter)
                }
            }
        }
    }
    
    // Method for displaying secondary tags with grey styling
    static func tags2View(tags2: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags2, id: \.self) { filter in
                    greyTagPill(filter)
                }
            }
        }
    }

}
