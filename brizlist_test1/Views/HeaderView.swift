//
//  HeaderView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 16/03/2025.
//

import Foundation
import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Background color for status bar area
            Color(.systemGray6)  // Light gray color that matches scroll areas
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
            
            // Header content
            HStack {
                Text("Brizlist")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Optional header actions can be added here
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))  // Same light gray color
            
            // Bottom border line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

#Preview {
    HeaderView()
}
