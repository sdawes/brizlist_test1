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
    
    // Compute the total number of active filters across all tag types
    private var totalActiveFilters: Int {
        return viewModel.selectedTags1.count + viewModel.selectedTags2.count + viewModel.selectedTags3.count + viewModel.selectedCardStates.count
    }
    
    // Determine filter button text based on active filters
    private var filterButtonText: String {
        if totalActiveFilters > 0 {
            return "Filtered (\(totalActiveFilters))"
        } else {
            return "Filter"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main header content
            HStack {
                Text("Brizlist")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                // Filter button with dynamic text
                Button(action: {
                    onFilterTap()
                }) {
                    Text(filterButtonText)
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(totalActiveFilters > 0 ? Color.blue.opacity(0.1) : Color.clear)
                        )
                        .foregroundColor(totalActiveFilters > 0 ? .blue : .primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(totalActiveFilters > 0 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))  // Fixed light gray background

            // Bottom border line removed
        }
    }
}

#Preview {
    HeaderView(
        viewModel: ListingsViewModel(),
        onFilterTap: {}
    )
}
