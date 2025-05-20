//
//  ContentView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ListingsViewModel()
    @State private var showingFilterSheet = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        ZStack {
            // Very light blue-gray gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.99),  // Lighter and bluer at top
                    Color(red: 0.92, green: 0.94, blue: 0.98)   // Slightly darker but still bluer at bottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header with fixed light gray background (defined in HeaderView)
                HeaderView(
                    viewModel: viewModel,
                    onFilterTap: { showingFilterSheet = true }
                )
                
                // Main scrolling content
                ListingsScrollView(
                    viewModel: viewModel,
                    onFilterTap: { showingFilterSheet = true },
                    sizeClass: sizeClass
                )
            }
        }
        .onAppear {
            viewModel.fetchListings()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") {
                viewModel.showError = false
            }
        } message: { errorMessage in
            Text(errorMessage)
        }
        .sheet(isPresented: $showingFilterSheet, content: {
            FilterSheetView(viewModel: viewModel)
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        })
    }
}

// Extracted ScrollView into a separate view
struct ListingsScrollView: View {
    @ObservedObject var viewModel: ListingsViewModel
    var onFilterTap: () -> Void
    let sizeClass: UserInterfaceSizeClass?
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("refresh")) {
                viewModel.fetchListings()
            }
            
            VStack(spacing: 16) {
                // Featured listings carousel at the top
                if !viewModel.getFeaturedListings().isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Section header
                        Text("FEATURED")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Color(red: 0.0, green: 0.4, blue: 0.9).opacity(0.8))
                            .cornerRadius(4)
                        
                        // Horizontal scrolling carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(viewModel.getFeaturedListings()) { listing in
                                    ListingCardView(listing: listing)
                                        .frame(width: UIScreen.main.bounds.width * 0.85) // 85% of screen width
                                        .id(listing.id)
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.trailing, -12) // Show a peek of the next card
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                
                // NEW listings carousel
                if !viewModel.getNewListings().isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Section header
                        Text("NEW")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(4)
                        
                        // Horizontal scrolling carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(viewModel.getNewListings()) { listing in
                                    ListingCardView(listing: listing)
                                        .frame(width: UIScreen.main.bounds.width * 0.85) // 85% of screen width
                                        .id(listing.id)
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.trailing, -12) // Show a peek of the next card
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                
                // COMING SOON listings carousel
                if !viewModel.getComingSoonListings().isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Section header
                        Text("COMING SOON")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Color(red: 1.0, green: 0.9, blue: 0.0).opacity(0.8))
                            .cornerRadius(4)
                        
                        // Horizontal scrolling carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(viewModel.getComingSoonListings()) { listing in
                                    ListingCardView(listing: listing)
                                        .frame(width: UIScreen.main.bounds.width * 0.85) // 85% of screen width
                                        .id(listing.id)
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.trailing, -12) // Show a peek of the next card
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                
                // Regular listing flow
                VStack(alignment: .leading, spacing: 12) {
                    // Section header for regular listings
                    Text("ALL LISTINGS")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color(red: 0.3, green: 0.3, blue: 0.35).opacity(0.8)) // Slate blue-gray color
                        .cornerRadius(4)
                    
                    LazyVStack(spacing: 16) {
                        // All remaining listings in a single flow, sorted alphabetically
                        ForEach(viewModel.getRegularListings()) { listing in
                            // The unified ListingCardView automatically handles all card states
                            ListingCardView(listing: listing)
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
                                        
                                        // FEATURED section
                                        if !viewModel.selectedCardStates.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                // Section title
                                                Text("FEATURED")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 4)
                                                
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 6) {
                                                        ForEach(Array(viewModel.selectedCardStates), id: \.self) { cardState in
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
                                                                             cardState == "featured" ? Color(red: 0.0, green: 0.4, blue: 0.9).opacity(0.3) :
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
                }
                
                // Loading indicator and end of list message
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
                
                if !viewModel.hasMoreListings && !viewModel.listings.isEmpty {
                    Text("No more listings to load")
                        .foregroundColor(.secondary)
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

