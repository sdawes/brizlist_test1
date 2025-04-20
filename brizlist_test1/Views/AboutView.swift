//
//  AboutView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 29/03/2025.
//

import Foundation
import SwiftUI

struct AboutSheetView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to Brizlist")
                    .font(.title3.bold())
                
                Text("We're a group of Bristol friends who love our city's incredible food and drink scene. Every restaurant, café, or bar you'll find here has been personally visited and recommended by our group.")
                    .font(.caption)
                
                Text("What makes us different? We don't just list places - we share the spots we genuinely love and return to. From hidden gems to local favorites, we're here to help you discover the best of Bristol's food scene.")
                    .font(.caption)
                
                Text("Use our data driven symbols to find places that match your needs, whether you're looking for vegetarian options, child-friendly spaces, or our special Briz Picks!")
                    .font(.caption)
                
                Divider()
                
                Text("Symbol Guide")
                    .font(.title3.bold())
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf")
                            .foregroundColor(.black)
                            .font(.caption)
                            .frame(width: 20, alignment: .center)
                        Text("Vegetarian Friendly")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.black)
                            .font(.caption)
                            .frame(width: 20, alignment: .center)
                        Text("Dog Friendly")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "figure.2.and.child.holdinghands")
                            .foregroundColor(.black)
                            .font(.caption)
                            .frame(width: 20, alignment: .center)
                        Text("Child Friendly")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.black)
                            .font(.caption)
                            .frame(width: 20, alignment: .center)
                        Text("Briz Pick - Our Favorites")
                            .font(.caption)
                    }
                }
                
                Spacer() // This will push content to the top
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AboutSheetView()
}
