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
    @State private var showingAddListing = false
    @State private var listingToEdit: Listing?
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Add the HeaderView at the top
                HeaderView()

                // Main scroll view
                ScrollView {
                    RefreshControl(coordinateSpace: .named("refresh")) {
                        viewModel.fetchListings()
                    }
                    
                    LazyVStack(spacing: 16) {
                        // Individual listing cards
                        ForEach(viewModel.listings) { listing in
                            ListingCardView(
                                listing: listing,
                                onEdit: { listingToEdit = $0 },
                                onDelete: { viewModel.deleteListing(listing: $0) }
                            )
                            .padding(.horizontal)
                            .buttonStyle(PlainButtonStyle())
                            .navigationBarHidden(true)
                            // Load more when reaching the last few items
                            .onAppear {
                                if listing.id == viewModel.listings.last?.id {
                                    viewModel.loadMoreListings()
                                }
                            }
                        }
                        
                        // Loading indicator at the bottom
                        if viewModel.isLoadingMoreListings {
                            ProgressView()
                                .padding()
                        }
                        
                        // Message when no more listings
                        if !viewModel.hasMoreListings && !viewModel.listings.isEmpty {
                            Text("No more listings to load")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 80) // Add padding at bottom to avoid toolbar overlap
                }
            }
            
            // Floating add button at bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingAddListing = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            viewModel.fetchListings()
        }
        .sheet(isPresented: $showingAddListing) {
            AddListingView(viewModel: viewModel)
        }
        .sheet(item: $listingToEdit) { listing in
            EditListingView(viewModel: viewModel, listing: listing)
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") {
                viewModel.showError = false
            }
        } message: { errorMessage in
            Text(errorMessage)
        }
        .coordinateSpace(name: "refresh")
    }
}

#Preview {
    ContentView()
}
