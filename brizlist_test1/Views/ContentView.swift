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
                
                // Main scrolling content now using the extracted component
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

