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
    @State private var showingAboutSheet = false
    
    var body: some View {
        ZStack {
            // System grey color to match the header
            Color(.systemGray6)  // This is the same color used in HeaderView
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    viewModel: viewModel,
                    onFilterTap: { showingFilterSheet = true },
                    onAboutTap: { showingAboutSheet = true }
                )
                
                // Main scrolling content
                ListingsScrollView(
                    viewModel: viewModel,
                    onFilterTap: { showingFilterSheet = true }
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
            .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $showingAboutSheet, content: {
            AboutSheetView()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        })
    }
}

// Extracted ScrollView into a separate view
struct ListingsScrollView: View {
    @ObservedObject var viewModel: ListingsViewModel
    var onFilterTap: () -> Void
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("refresh")) {
                viewModel.fetchListings()
            }
            
            LazyVStack(spacing: 16) {
                // All listings in a single flow, sorted with new at top then alphabetically
                ForEach(viewModel.listings) { listing in
                    // The unified ListingCardView automatically handles all card states
                    ListingCardView(listing: listing)
                        .padding(.horizontal)
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
                        
                        if !viewModel.selectedTags1.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected filters:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    ForEach(Array(viewModel.selectedTags1), id: \.self) { filter in
                                        Text(filter.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.7))
                                            )
                                    }
                                }
                            }
                            .padding(.top, 4)
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
            .padding(.top)
            .padding(.bottom, 80)
        }
        .coordinateSpace(name: "refresh")
    }
}

#Preview {
    ContentView()
}
