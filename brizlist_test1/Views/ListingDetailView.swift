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
    
    // Example dummy data for previews
    static let previewListing = Listing(
        id: "123",
        name: "Pasta Loco",
        typeFilters: ["restaurant", "italian"],
        cuisine: "Italian",
        shortDescription: "A cozy spot in the heart of Bristol",
        location: "Bristol",
        imageUrl: "https://example.com/image.jpg",
        isBrizPick: true,
        isFeatured: false
    )
    
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
                        if !listing.typeFilters.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(listing.typeFilters, id: \.self) { tag in
                                        TagView(tag: tag.capitalized)
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        
                        if !listing.cuisine.isEmpty {
                            Text(listing.cuisine)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Description
                    if !listing.shortDescription.isEmpty {
                        Text(listing.shortDescription)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 16)
                    } else {
                        // Fallback description
                        Text("A beloved local spot that's been serving Bristol for years. Known for their exceptional service and welcoming atmosphere, this place has become a cornerstone of the community.")
                            .font(.caption)
                        
                        Text("Whether you're stopping by for a quick visit or settling in for a longer stay, you'll find yourself surrounded by the warm, authentic vibe that makes Bristol's food scene so special.")
                            .font(.caption)
                        
                        Text("Make sure to check out their seasonal specials and don't forget to ask about their house recommendations!")
                            .font(.caption)
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

#Preview {
    ListingDetailView(listing: Listing(
        id: "1",
        name: "The Bristol Lounge",
        typeFilters: ["restaurant", "italian"],
        cuisine: "Italian",
        shortDescription: "A cozy spot in the heart of Bristol",
        location: "Clifton, Bristol"
    ))
}
