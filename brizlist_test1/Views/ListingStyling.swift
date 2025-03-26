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
        let color: Color
        
        // Determine color based on category
        switch category.lowercased() {
        case "restaurant":
            color = .orange
        case "pub":
            color = .brown
        case "coffee shop":
            color = .blue
        case "bar":
            color = .purple
        default:
            color = .gray
        }
        
        // Return the styled text view with tag icon
        return HStack(spacing: 4) {
            Image(systemName: "tag.fill")
                .font(.caption)
            
            Text(category)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(6)
    }
    
    
    // MARK: - Type Styling
    
    static func typeTextView(_ type: String) -> some View {
        let color: Color
        
        // Determine color based on type
        switch type.lowercased() {
        case "fine dining":
            color = .red
        case "gastro":
            color = .green
        case "casual":
            color = .blue
        default:
            color = .gray
        }
        
        // Return the styled text view
        return Text(type)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }

    // MARK: - Location Styling
    
    static func locationTextView(_ location: String) -> some View {
        Text(location)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.teal)
            .cornerRadius(6)
    }


    // Single function that handles all location styling
    static func categoryLocationView(_ location: String) -> some View {
        let color: Color
        
        // Determine color based on location
        switch location.lowercased() {
        case "clifton":
            color = .orange
        case "redcliffe":
            color = .brown
        case "bedminster":
            color = .blue
        case "city centre":
            color = .purple
        default:
            color = .gray
        }
        
        // Return the styled text view with pin icon
        return HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.caption)
            
            Text(location)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(6)
    }
}
