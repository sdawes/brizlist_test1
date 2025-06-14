//
//  ListingDetailView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//
//  PULL QUOTE SYNTAX:
//  To add pull quotes to your longDescription, use: [quote]Your compelling quote here[/quote]
//  The quote will be automatically extracted and displayed as a highlighted pull quote.
//  The quote text will be removed from the main description to avoid duplication.
//

import SwiftUI

// MARK: - Content Block Types

enum ContentBlockType {
    case text
    case quote
}

struct ContentBlock {
    let type: ContentBlockType
    let content: String
}

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
    @State private var currentImageIndex: Int = 0
    
    // MARK: - Pull Quote Parsing
    
    /// Parse longDescription into content blocks with inline pull quotes
    private func parseContentBlocks(from text: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        var remainingText = text
        
        let pattern = "\\[quote\\](.*?)\\[/quote\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            // If regex fails, return the whole text as one block
            return [ContentBlock(type: .text, content: text)]
        }
        
        let range = NSRange(location: 0, length: remainingText.utf16.count)
        let matches = regex.matches(in: remainingText, options: [], range: range)
        
        var lastEnd = 0
        
        for match in matches {
            // Add text before the quote
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                if let textRange = Range(beforeRange, in: remainingText) {
                    let beforeText = String(remainingText[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !beforeText.isEmpty {
                        blocks.append(ContentBlock(type: .text, content: beforeText))
                    }
                }
            }
            
            // Add the quote
            let quoteRange = match.range(at: 1)
            if let quoteTextRange = Range(quoteRange, in: remainingText) {
                let quoteText = String(remainingText[quoteTextRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !quoteText.isEmpty {
                    blocks.append(ContentBlock(type: .quote, content: quoteText))
                }
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // Add remaining text after the last quote
        if lastEnd < remainingText.utf16.count {
            let afterRange = NSRange(location: lastEnd, length: remainingText.utf16.count - lastEnd)
            if let textRange = Range(afterRange, in: remainingText) {
                let afterText = String(remainingText[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !afterText.isEmpty {
                    blocks.append(ContentBlock(type: .text, content: afterText))
                }
            }
        }
        
        return blocks.isEmpty ? [ContentBlock(type: .text, content: text)] : blocks
    }
    
    /// Extract pull quotes from longDescription using [quote]...[/quote] syntax
    private func extractPullQuote(from text: String) -> String? {
        let pattern = "\\[quote\\](.*?)\\[/quote\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            let quoteRange = Range(match.range(at: 1), in: text)
            return quoteRange.map { String(text[$0]).trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        return nil
    }
    
    /// Remove pull quote markup from text for clean display
    private func cleanDescriptionText(_ text: String) -> String {
        let pattern = "\\[quote\\].*?\\[/quote\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return text
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let cleanText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        
        // Clean up any double line breaks that might result from removing quotes
        return cleanText.replacingOccurrences(of: "\n\n\n", with: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
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
    
    // MARK: - Image Carousel
    
    /// Get all images for the carousel (main image + additional images)
    private var allImages: [String] {
        var images: [String] = []
        
        // Add main image first
        if let mainImage = listing.imageUrl {
            images.append(mainImage)
        }
        
        // Add additional images
        images.append(contentsOf: listing.additionalImages)
        
        return images
    }
    
    /// Check if we should show carousel (more than one image)
    private var shouldShowCarousel: Bool {
        return allImages.count > 1
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image at the top - contained within safe area
                    if shouldShowCarousel {
                        CarouselView(images: allImages, currentIndex: $currentImageIndex)
                            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 280)
                    } else if let imageUrl = listing.imageUrl {
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
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(listing.location)
                                    .font(.system(size: 12, weight: .medium))
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
                            // Review text with editorial styling and inline quotes
                            if !listing.longDescription.isEmpty {
                                let contentBlocks = parseContentBlocks(from: listing.longDescription)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(Array(contentBlocks.enumerated()), id: \.offset) { index, block in
                                        if block.type == .text {
                                            Text(block.content)
                                                .font(.system(size: 15, weight: .regular))
                                                .lineSpacing(6)
                                                .fixedSize(horizontal: false, vertical: true)
                                        } else if block.type == .quote {
                                            // Inline pull quote with quotation mark
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("\"")
                                                    .font(.system(size: 32, weight: .light))
                                                    .foregroundColor(.gray)
                                                    .offset(y: -4)
                                                
                                                Text(block.content)
                                                    .font(.system(size: 17, weight: .bold))
                                                    .italic()
                                                    .foregroundColor(.primary)
                                                    .lineSpacing(4)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                            } else if !listing.shortDescription.isEmpty {
                                Text(listing.shortDescription)
                                    .font(.system(size: 15, weight: .regular))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
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

// MARK: - Carousel View Component

struct CarouselView: View {
    let images: [String]
    @Binding var currentIndex: Int
    @State private var tabViewId = UUID()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Image carousel
            TabView(selection: $currentIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    FirebaseStorageImage(urlString: images[index])
                        .aspectRatio(4/3, contentMode: .fill)
                        .frame(maxWidth: UIScreen.main.bounds.width)
                        .frame(height: 280)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 280)
            .id(tabViewId)
            .onAppear {
                // Reset the TabView by generating a new ID
                tabViewId = UUID()
                currentIndex = 0
            }
            .onChange(of: images.count) { _ in
                // Regenerate TabView when images change
                tabViewId = UUID()
                currentIndex = 0
            }
            
            // Custom page indicators
            if images.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}
