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
            // System grey color to match the header
            Color(.systemGray6)  // This is the same color used in HeaderView
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                HeaderView(viewModel: viewModel)
                ListingsScrollView(viewModel: viewModel, listingToEdit: $listingToEdit)
            }
            
            // Floating add button
            FloatingAddButton(showingAddListing: $showingAddListing)
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
    }
}

// Extracted ScrollView into a separate view
struct ListingsScrollView: View {
    @ObservedObject var viewModel: ListingsViewModel
    @Binding var listingToEdit: Listing?
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("refresh")) {
                viewModel.fetchListings()
            }
            
            LazyVStack(spacing: 16) {
                ForEach(viewModel.listings) { listing in
                    ListingCardView(
                        listing: listing,
                        onEdit: { listingToEdit = $0 },
                        onDelete: { viewModel.deleteListing($0) }
                    )
                    .padding(.horizontal)
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if listing.id == viewModel.listings.last?.id {
                            viewModel.loadMoreListings()
                        }
                    }
                }
                
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

// Extracted Floating Add Button
struct FloatingAddButton: View {
    @Binding var showingAddListing: Bool
    
    var body: some View {
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
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    ContentView()
}
