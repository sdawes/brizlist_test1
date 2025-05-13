//
//  HeaderView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 16/03/2025.
//

import Foundation
import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: ListingsViewModel
    var onFilterTap: () -> Void
    var onAboutTap: () -> Void
    
    // Compute the total number of active filters across all tag types
    private var totalActiveFilters: Int {
        return viewModel.selectedTags1.count + viewModel.selectedTags2.count + viewModel.selectedTags3.count + viewModel.selectedCardStates.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main header content
            HStack {
                Text("Brizlist")
                    .font(.headline)
                    .fontWeight(.bold)

                if viewModel.isFiltering {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        // Show the total count of all selected tags
                        Text("\(totalActiveFilters)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                // Filter button
                Button(action: {
                    onFilterTap()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.headline)
                        .foregroundColor(.black)
                }

                // More info about brizlist
                Button(action: {
                    onAboutTap()
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))

            // Bottom border line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

#Preview {
    HeaderView(
        viewModel: ListingsViewModel(),
        onFilterTap: {},
        onAboutTap: {}
    )
}
