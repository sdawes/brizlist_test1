//
//  ListingDetailView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import SwiftUI

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
                            .onAppear {
                                print("📷 Detail view loading image: \(imageUrl)")
                            }
                    }
                    
                    Text(listing.name)
                        .font(.title3.bold())
                    
                    HStack {
                        if !listing.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(listing.tags, id: \.self) { tag in
                                        ListingStyling.tagPill(tag)
                                    }
                                }
                            }
                        }
                        
                        if !listing.cuisine.isEmpty {
                            Text(listing.cuisine)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Use the actual description if available
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.caption)
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
        tags: ["restaurant", "italian"],
        cuisine: "Italian",
        description: "A cozy spot in the heart of Bristol",
        location: "Clifton, Bristol"
    ))
}
