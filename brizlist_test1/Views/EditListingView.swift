//
//  EditListingView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//  Note: This view is no longer used as edit functionality has been removed.

import Foundation
import SwiftUI

struct EditListingView: View {
    @Environment(\.dismiss) var dismiss
    var listing: Listing
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Editing functionality has been removed")
                    .padding()
                
                Button("Close") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("View Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 