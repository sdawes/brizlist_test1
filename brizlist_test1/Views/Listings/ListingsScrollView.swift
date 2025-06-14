//
//  ListingsScrollView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI

/// A scrollable view that displays all listing categories in a vertical layout
struct ListingsScrollView: View {
    @ObservedObject var viewModel: ListingsViewModel
    var onFilterTap: () -> Void
    let sizeClass: UserInterfaceSizeClass?
    @State private var curatedListsRefreshId = UUID()
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("refresh")) {
                viewModel.fetchListings()
                // Trigger refresh for curated lists by changing the ID
                curatedListsRefreshId = UUID()
            }
            
            VStack(spacing: 16) {
                // Curated Lists Section - only show when no filters are active
                if !viewModel.hasTagFilters {
                    CuratedListsContainerView()
                        .id(curatedListsRefreshId)
                }
                
                // All listings section
                if !viewModel.listings.isEmpty {
                    SectionHeaderView(title: "ALL LISTINGS")
                }
                
                LazyVStack(spacing: 16) {
                    // All listings in a single flow, sorted alphabetically
                    ForEach(viewModel.listings) { listing in
                        // Use appropriate card view based on cardStyling
                        Group {
                            if listing.cardStyling == "large" {
                                LargeCardView(listing: listing)
                            } else if listing.cardStyling == "new" {
                                NewCardView(listing: listing)
                            } else if listing.cardStyling == "coming" {
                                ComingSoonCardView(listing: listing)
                            } else {
                                DefaultCardView(listing: listing)
                            }
                        }
                        .id(listing.id)
                        .onAppear {
                            if listing.id == viewModel.listings.last?.id {
                                viewModel.loadMoreListings()
                            }
                        }
                    }
                    
                    // No results message when filtering results in no matches
                    if viewModel.noResultsFromFiltering {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                            
                            Text("No listings match all your filters")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Try selecting fewer filters or a different combination")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            // Show selected filters
                            if viewModel.hasTagFilters {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Selected filters:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                                                          // CARD STYLING section
                                    if !viewModel.selectedCardStyling.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Section title
                                            Text("CARD STYLING")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 6) {
                                                    ForEach(Array(viewModel.selectedCardStyling), id: \.self) { cardState in
                                                        Text(cardState.uppercased())
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.black)
                                                            .padding(.vertical, 4)
                                                            .padding(.horizontal, 8)
                                                            .background(
                                                                Rectangle()
                                                                                                .fill(cardState == "new" ? Color.green.opacity(0.3) :
                                 cardState == "coming" ? Color(red: 1.0, green: 0.9, blue: 0.0).opacity(0.3) :
                                 cardState == "large" ? Color(red: 0.0, green: 0.4, blue: 0.9).opacity(0.3) :
                                                                         Color.blue.opacity(0.3))
                                                            )
                                                    }
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                        }
                                    }
                                    
                                    // TYPE section (Primary tags/cream)
                                    if !viewModel.selectedTags1.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Section title
                                            Text("TYPE")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 6) {
                                                    ForEach(Array(viewModel.selectedTags1), id: \.self) { tag in
                                                        Text(tag.uppercased())
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.black)
                                                            .padding(.vertical, 4)
                                                            .padding(.horizontal, 8)
                                                            .background(
                                                                Rectangle()
                                                                    .fill(Color(red: 0.93, green: 0.87, blue: 0.76))
                                                            )
                                                    }
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                        }
                                    }
                                    
                                    // VIBE section (Secondary tags/grey)
                                    if !viewModel.selectedTags2.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Section title
                                            Text("VIBE")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 6) {
                                                    ForEach(Array(viewModel.selectedTags2), id: \.self) { tag in
                                                        Text(tag.uppercased())
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.black)
                                                            .padding(.vertical, 4)
                                                            .padding(.horizontal, 8)
                                                            .background(
                                                                Rectangle()
                                                                    .fill(Color.gray.opacity(0.2))
                                                            )
                                                    }
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                        }
                                    }
                                    
                                    // CUISINE section (Tertiary tags/purple)
                                    if !viewModel.selectedTags3.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Section title
                                            Text("CUISINE")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 6) {
                                                    ForEach(Array(viewModel.selectedTags3), id: \.self) { tag in
                                                        Text(tag.uppercased())
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.black)
                                                            .padding(.vertical, 4)
                                                            .padding(.horizontal, 8)
                                                            .background(
                                                                Rectangle()
                                                                    .fill(Color.purple.opacity(0.15))
                                                            )
                                                    }
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                        }
                                    }
                                    
                                    // LOCATION section (teal/aqua)
                                    if !viewModel.selectedLocationTags.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Section title
                                            Text("LOCATION")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 6) {
                                                    ForEach(Array(viewModel.selectedLocationTags), id: \.self) { tag in
                                                        Text(tag.uppercased())
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.black)
                                                            .padding(.vertical, 4)
                                                            .padding(.horizontal, 8)
                                                            .background(
                                                                Rectangle()
                                                                    .fill(Color(red: 0.75, green: 0.87, blue: 0.85))
                                                            )
                                                    }
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 12)
                                .padding(.horizontal)
                            }
                            
                            Button("Adjust Filters") {
                                // This will open the filter sheet
                                onFilterTap()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                
                // Loading indicator
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal, 16) // Add consistent horizontal padding to the entire content
            // Use sizeClass for the ID
            .id("scrollview-\(sizeClass == .regular ? "regular" : "compact")")
            .padding(.top)
            .padding(.bottom, 80)
        }
        .coordinateSpace(name: "refresh")
    }
}

#Preview {
    ListingsScrollView(
        viewModel: ListingsViewModel(),
        onFilterTap: {},
        sizeClass: .compact
    )
}



