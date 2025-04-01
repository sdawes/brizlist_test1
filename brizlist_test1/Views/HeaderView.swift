//
//  HeaderView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 16/03/2025.
//

import Foundation
import SwiftUI

struct HeaderView: View {
    @State private var showingFilterSheet = false
    @State private var showingAboutSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Background color for status bar area
            Color(.systemGray6)
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
            
            // Main header content
            HStack {
                Text("Brizlist")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                // Filter button
                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.headline)
                        .foregroundColor(.black)
                }

                // More info about brizlist
                Button(action: {
                    showingAboutSheet = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))

            // Bottom border line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
        .sheet(isPresented: $showingFilterSheet, content: {
            FilterSheetView()
            .presentationDetents([.medium])
        })
        .sheet(isPresented: $showingAboutSheet, content: {
            AboutSheetView()
            .presentationDetents([.large])
        })
    }
}

#Preview {
    HeaderView()
}
