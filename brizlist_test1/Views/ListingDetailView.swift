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
    let isSecondary: Bool
    
    init(tag: String, isSecondary: Bool = false) {
        self.tag = tag
        self.isSecondary = isSecondary
    }
    
    var body: some View {
        Text(tag)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(
                Capsule().fill(isSecondary ? Color.gray.opacity(0.2) : Color(red: 0.93, green: 0.87, blue: 0.76))
            )
    }
}

struct ListingDetailView: View {
    let listing: Listing
    @Environment(\.dismiss) var dismiss
    @State private var tagsHeight: CGFloat = 0
    
    // Simple wrapping HStack for tags with dynamic height
    private var wrappingTagsView: some View {
        GeometryReader { geometry in
            self.generateTagsContent(in: geometry)
                .background(
                    GeometryReader { heightGeometry -> Color in
                        let height = heightGeometry.size.height
                        DispatchQueue.main.async {
                            if height > 0 {
                                self.tagsHeight = height
                            }
                        }
                        return Color.clear
                    }
                )
        }
    }
    
    private func generateTagsContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        // Combine tags1 and tags2
        let allTags: [(String, Bool)] = listing.tags1.map { ($0, false) } + listing.tags2.map { ($0, true) }
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(allTags.enumerated()), id: \.offset) { index, tagInfo in
                let tag = tagInfo.0
                let isSecondary = tagInfo.1
                
                Group {
                    if isSecondary {
                        ListingStyling.greyTagPill(tag)
                    } else {
                        ListingStyling.tagPill(tag)
                    }
                }
                    .padding([.trailing, .bottom], 2)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if index == allTags.count - 1 {
                            width = 0 // last item
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == allTags.count - 1 {
                            height = 0 // last item
                        }
                        return result
                    }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero image at the top with proper width constraints
                    if let imageUrl = listing.imageUrl {
                        FirebaseStorageImage(urlString: imageUrl)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(maxWidth: UIScreen.main.bounds.width - 40)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                    }
                    
                    Text(listing.name)
                        .font(.title3.bold())
                    
                    // Combined tags - both primary and secondary in a continuous flow with wrapping
                    if !listing.tags1.isEmpty || !listing.tags2.isEmpty {
                        wrappingTagsView
                            .frame(height: tagsHeight > 0 ? tagsHeight : (listing.tags1.isEmpty && listing.tags2.isEmpty ? 0 : 30))
                            .padding(.bottom, 8)
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
