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
                .frame(height: 24)
            
            // Title and horizontal line
            VStack(spacing: 8) {
                // Section title
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Horizontal line underneath
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal)
            }
            
            // Bottom spacing before section content
            Spacer()
                .frame(height: 16)
        }
    }
}

#Preview {
    VStack {
        SectionHeaderView(title: "FEATURED")
        SectionHeaderView(title: "NEW")
        SectionHeaderView(title: "COMING SOON")
    }
}

