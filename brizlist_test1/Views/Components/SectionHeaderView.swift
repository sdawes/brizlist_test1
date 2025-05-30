//
//  SectionHeaderView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 29/05/2025.
//

import SwiftUI

/// A reusable section header component with title and horizontal divider
/// - Provides consistent styling across all section headers
/// - Includes proper vertical spacing and horizontal line
/// - Can be expanded with different styles in the future
struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing
            Spacer()
                .frame(height: 12)
            
            // Title and horizontal line
            VStack(spacing: 8) {
                // Section title - left aligned with card edges
                HStack {
                    Text(title.lowercased())
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Horizontal line underneath - full width aligned with cards
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Bottom spacing before section content
            Spacer()
                .frame(height: 16)
        }
    }
}


