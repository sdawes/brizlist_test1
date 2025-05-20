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
    @State private var deviceOrientation = UIDevice.current.orientation
    
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
                    sizeClass: sizeClass,
                    deviceOrientation: deviceOrientation
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                self.deviceOrientation = UIDevice.current.orientation
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
    let deviceOrientation: UIDeviceOrientation
    
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
                        // Use both listing ID and orientation state to force refresh when orientation changes
                        .id("\(listing.id)-\(deviceOrientation.isLandscape ? "landscape" : "portrait")")
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
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Selected filters:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                // Card states (new and featured)
                                if !viewModel.selectedCardStates.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(Array(viewModel.selectedCardStates), id: \.self) { cardState in
                                                Text(cardState.uppercased())
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(cardState == "new" ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                // Primary tags (cream)
                                if !viewModel.selectedTags1.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(Array(viewModel.selectedTags1), id: \.self) { tag in
                                                Text(tag.capitalized)
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color(red: 0.93, green: 0.87, blue: 0.76))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                // Secondary tags (grey)
                                if !viewModel.selectedTags2.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(Array(viewModel.selectedTags2), id: \.self) { tag in
                                                Text(tag.capitalized)
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.gray.opacity(0.2))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                // Tertiary tags (purple)
                                if !viewModel.selectedTags3.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(Array(viewModel.selectedTags3), id: \.self) { tag in
                                                Text(tag.capitalized)
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.purple.opacity(0.15))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
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
            // Use both sizeClass and orientation for the ID
            .id("scrollview-\(sizeClass == .regular ? "regular" : "compact")-\(deviceOrientation.isLandscape ? "landscape" : "portrait")")
            .padding(.top)
            .padding(.bottom, 80)
        }
        .coordinateSpace(name: "refresh")
    }
}

#Preview {
    ContentView()
}
