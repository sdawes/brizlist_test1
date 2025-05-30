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
        
        // Combine tags1, tags2, and tags3
        let allTags: [(String, Int)] = 
            listing.tags1.map { ($0, 1) } + 
            listing.tags2.map { ($0, 2) } + 
            listing.tags3.map { ($0, 3) }
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(allTags.enumerated()), id: \.offset) { index, tagInfo in
                let tag = tagInfo.0
                let tagType = tagInfo.1
                
                Group {
                    if tagType == 1 {
                        // Primary tags (cream background)
                        ListingStyling.tagPill(tag)
                    } else if tagType == 2 {
                        // Secondary tags (light grey background)
                        ListingStyling.greyTagPill(tag)
                    } else {
                        // Tertiary tags (light purple background)
                        ListingStyling.purpleTagPill(tag)
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
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image at the top - contained within safe area
                    if let imageUrl = listing.imageUrl {
                        FirebaseStorageImage(urlString: imageUrl)
                            .aspectRatio(4/3, contentMode: .fill)
                            .frame(maxWidth: UIScreen.main.bounds.width)
                            .frame(height: 280)
                            .clipped()
                    }
                    
                    // Content container with proper editorial spacing
                    VStack(alignment: .leading, spacing: 24) {
                        // Header section
                        VStack(alignment: .leading, spacing: 12) {
                            // Title with editorial styling
                            Text(listing.name)
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Subtitle/location with refined styling
                            HStack(spacing: 8) {
                                Image(systemName: "location")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(listing.location)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                            }
                            
                            // Tags with refined spacing
                            if !listing.tags1.isEmpty || !listing.tags2.isEmpty || !listing.tags3.isEmpty {
                                wrappingTagsView
                                    .frame(height: tagsHeight > 0 ? tagsHeight : 30)
                            }
                        }
                        
                        // Divider
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                            .padding(.vertical, 8)
                        
                        // Main review content
                        VStack(alignment: .leading, spacing: 20) {
                            // Review text with editorial styling
                            if !listing.longDescription.isEmpty {
                                Text(listing.longDescription)
                                    .font(.system(size: 16, weight: .regular))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if !listing.shortDescription.isEmpty {
                                Text(listing.shortDescription)
                                    .font(.system(size: 16, weight: .regular))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            // Pull quote or highlight (if description is long enough)
                            if !listing.longDescription.isEmpty && listing.longDescription.count > 100 {
                                VStack(alignment: .leading, spacing: 12) {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: 4, height: 40)
                                    
                                    Text("The kind of place that feels special without being over the top")
                                        .font(.system(size: 20, weight: .medium))
                                        .italic()
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)
                                }
                                .padding(.leading, 16)
                                .padding(.vertical, 16)
                            }
                        }
                        
                        // Bottom spacing
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .frame(maxWidth: UIScreen.main.bounds.width - 48) // Account for horizontal padding
                }
                .frame(maxWidth: UIScreen.main.bounds.width) // Constrain entire container
                .background(Color(.systemBackground))
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // X button to close the detail view - same styling as FilterSheetView
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(Color.blue.opacity(0.4))
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 24, height: 24)
                            )
                    }
                }
            }
        }
    }
}
