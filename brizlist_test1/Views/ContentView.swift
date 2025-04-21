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
    
    var body: some View {
        ZStack {
            // System grey color to match the header
            Color(.systemGray6)  // This is the same color used in HeaderView
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                HeaderView(viewModel: viewModel)
                ListingsScrollView(viewModel: viewModel)
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
    }
}

// Extracted ScrollView into a separate view
struct ListingsScrollView: View {
    @ObservedObject var viewModel: ListingsViewModel
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("refresh")) {
                viewModel.fetchListings()
            }
            
            LazyVStack(spacing: 16) {
                // Featured listings section
                if !viewModel.featuredListings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Featured section header with enhanced styling
                        HStack {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                            
                            Text("FEATURED")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        
                        // Featured listings
                        ForEach(viewModel.featuredListings) { listing in
                            ListingCardView(
                                listing: listing
                            )
                            .padding(.horizontal)
                            .onAppear {
                                if listing.id == viewModel.featuredListings.last?.id {
                                    viewModel.loadMoreListings()
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.08)) // Very light blue background
                            .padding(.horizontal, 8)
                    )
                    
                    // Add a bit more space after the featured section
                    Spacer()
                        .frame(height: 12)
                }
                
                // Regular listings
                ForEach(viewModel.listings) { listing in
                    ListingCardView(
                        listing: listing
                    )
                    .padding(.horizontal)
                    .onAppear {
                        if listing.id == viewModel.listings.last?.id {
                            viewModel.loadMoreListings()
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
            .padding(.top)
            .padding(.bottom, 80)
        }
        .coordinateSpace(name: "refresh")
    }
}

#Preview {
    ContentView()
}
