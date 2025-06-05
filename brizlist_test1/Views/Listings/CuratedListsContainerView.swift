//
//  CuratedListsContainerView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 31/05/2025.
//

import SwiftUI

/// Container view that manages and displays all curated lists
/// - Handles fetching curated lists from Firestore
/// - Displays each curated list as a section
/// - Maintains separation of concerns from main listings view
struct CuratedListsContainerView: View {
    @StateObject private var curatedListViewModel = CuratedListViewModel()
    
    var body: some View {
        // Only show if we have curated lists
        if !curatedListViewModel.curatedLists.isEmpty {
            VStack(spacing: 0) {
                ForEach(curatedListViewModel.curatedLists) { curatedList in
                    CuratedListSectionView(
                        curatedList: curatedList, 
                        curatedListViewModel: curatedListViewModel
                    )
                }
            }
            .padding(.vertical, 24)
        }
    }
    
    /// Refresh curated lists data (called by parent when refresh is triggered)
    func refresh() {
        curatedListViewModel.clearCache()
        curatedListViewModel.fetchCuratedLists()
    }
}

// MARK: - Curated List Section Component

struct CuratedListSectionView: View {
    let curatedList: CuratedList
    let curatedListViewModel: CuratedListViewModel
    @State private var listings: [Listing] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 12) {
            // Enhanced section header for curated lists
            CuratedSectionHeaderView(
                title: curatedList.title,
                description: curatedList.description
            )
            
            if isLoading {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading curated list...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if listings.isEmpty {
                // Empty state
                Text("No listings available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                // Display curated listings
                VStack(spacing: 12) {
                    ForEach(listings) { listing in
                        // Use DefaultCardView for all curated listings regardless of their state
                        // This creates a consistent look within curated sections
                        DefaultCardView(listing: listing)
                    }
                }
            }
        }
        .padding(.bottom, 8)
        .onAppear {
            fetchListings()
        }
    }
    
    private func fetchListings() {
        isLoading = true
        curatedListViewModel.fetchListingsForCuratedList(curatedList) { fetchedListings in
            self.listings = fetchedListings
            self.isLoading = false
        }
    }
}

// MARK: - Enhanced Curated Section Header

/// An enhanced section header specifically for curated lists
/// - Uses larger font size and different color scheme
/// - Includes "CURATED" badge for clear distinction
/// - Maintains same spacing structure as regular headers
struct CuratedSectionHeaderView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing
            Spacer()
                .frame(height: 12)
            
            // Enhanced title section with badge
            VStack(spacing: 10) {
                // Title row with curated badge
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Small "CURATED" badge
                        Text("CURATED")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                        
                        // Main title - larger and more prominent
                        Text(title.lowercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Description underneath the title
                        if !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Spacer()
                }
                
                // Horizontal line underneath - slightly thicker for emphasis
                Rectangle()
                    .fill(Color.orange.opacity(0.4))
                    .frame(height: 2)
            }
            
            // Bottom spacing before section content
            Spacer()
                .frame(height: 18)
        }
    }
}

#Preview {
    CuratedListsContainerView()
}

