//
//  ListingDetailView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import SwiftUI

// TagView component for displaying tags
struct TagView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(Capsule().fill(Color(red: 0.93, green: 0.87, blue: 0.76)))
    }
}

struct ListingDetailView: View {
    let listing: Listing
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero image at the top
                    if let imageUrl = listing.imageUrl {
                        FirebaseStorageImage(urlString: imageUrl)
                            .frame(height: 220)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                    }
                    
                    Text(listing.name)
                        .font(.title3.bold())
                    
                    HStack {
                        if !listing.tags1.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(listing.tags1, id: \.self) { tag in
                                        TagView(tag: tag.capitalized)
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    
                    // Description
                    if !listing.longDescription.isEmpty {
                        Text(listing.longDescription)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 16)
                    } else if !listing.shortDescription.isEmpty {
                        // Fall back to shortDescription if longDescription is empty
                        Text(listing.shortDescription)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 16)
                    } else {
                        // Simple fallback message
                        Text("Description not available at this time")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                    }
                    
                    // Location information
                    if !listing.location.isEmpty {
                        Divider()
                        
                        Text("Location")
                            .font(.title3.bold())
                            
                        HStack(spacing: 8) {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.black)
                                .font(.caption)
                                .frame(width: 20, alignment: .center)
                            Text(listing.location)
                                .font(.caption)
                        }
                    }
                    
                    Divider()
                    
                    Text("Opening Hours")
                        .font(.title3.bold())
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.black)
                                .font(.caption)
                                .frame(width: 20, alignment: .center)
                            Text("Mon-Fri: 9am - 10pm")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.black)
                                .font(.caption)
                                .frame(width: 20, alignment: .center)
                            Text("Sat-Sun: 10am - 11pm")
                                .font(.caption)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
