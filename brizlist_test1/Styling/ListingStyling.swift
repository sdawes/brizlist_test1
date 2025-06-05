//
//  ListingStyling.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 18/03/2025.
//

import Foundation
import SwiftUI

struct ListingStyling {
    // MARK: - Colors
    
    // Dark gray color for filter buttons
    static let darkGray = Color(red: 0.3, green: 0.3, blue: 0.3)
    
    // MARK: - Filter Sheet Styling
    
    // Close button (X in a circle)
    static func closeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(darkGray)
            }
        }
    }
    
    // Reset button (arrow.counterclockwise in a circle)
    static func resetButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(darkGray)
            }
        }
    }
    
    // Apply button style
    static func applyButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    // MARK: - Location Styling
    
    static func locationTextView(_ location: String) -> some View {
        Text(location.lowercased())
            .font(.caption)
            .foregroundColor(.black)
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

    // Purple tag pill for tertiary tags
    static func purpleTagPill(_ tag: String) -> some View {
        return Text(tag.uppercased())
            .font(.system(size: 10))
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 2.5)
            .padding(.horizontal, 7)
            .background(
                Rectangle()
                    .fill(Color.purple.opacity(0.15))
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
    
    // Method for displaying tertiary tags with purple styling
    static func tags3View(tags3: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags3, id: \.self) { filter in
                    purpleTagPill(filter)
                }
            }
        }
    }
}
