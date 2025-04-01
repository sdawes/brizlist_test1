//
//  ImageViewModel.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 17/03/2025.
//

import SwiftUI
import Foundation

class ImageViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    // Checks if the url string is valid
    func loadImage(from urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        
        // Check cache first
        if let cachedImage = Self.imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        isLoading = true

        // creates a data task with the URLSession to fetch the image data
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    print("DEBUG - Image loading error: \(error.localizedDescription) for URL: \(urlString)")
                    return
                }
                
                guard let data = data, let loadedImage = UIImage(data: data) else {
                    print("DEBUG - Failed to create image from data for URL: \(urlString)")
                    return
                }
                
                // Cache the image
                Self.imageCache.setObject(loadedImage, forKey: urlString as NSString)
                self?.image = loadedImage
            }
        }.resume()
    }
}
//
//  ListingsViewModel.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class ListingsViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isLoadingMoreListings: Bool = false
    @Published var hasMoreListings: Bool = true
    
    private let db = Firestore.firestore()
    private let pageSize = 10 // Number of listings per page
    private var lastDocument: DocumentSnapshot?
    
    // Read Listings
    
    func fetchListings() {
        // Clear existing listings and reset pagination state
        listings = []
        lastDocument = nil
        hasMoreListings = true
        
        // Set up initial query with limit
        db.collection("listings")
            .order(by: "name")
            .limit(to: pageSize)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error fetching listings: \(error.localizedDescription)"
                    self.showError = true
                    print("❌ Error fetching listings: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // No documents found
                    self.listings = []
                    self.hasMoreListings = false
                    return
                }
                
                // Save the last document for pagination
                self.lastDocument = documents.last
                
                // Check if we've reached the end
                if documents.count < self.pageSize {
                    self.hasMoreListings = false
                } else {
                    self.hasMoreListings = true
                }
                
                // Manual decoding
                self.listings = documents.compactMap { document in
                    let data = document.data()
                    let id = document.documentID
                    
                    // Check if all required fields exist
                    guard 
                        let name = data["name"] as? String,
                        let category = data["category"] as? String,
                        let description = data["description"] as? String,
                        let type = data["type"] as? String,
                        let location = data["location"] as? String
                    else {
                        print("❌ Skipping document \(id) due to missing required fields")
                        return nil
                    }
                    
                    // imageURL remains optional
                    let imageURL = data["imageURL"] as? String
                    let isBrizPick = data["isBrizPick"] as? Bool
                    
                    return Listing(
                        id: id,
                        name: name,
                        category: category,
                        description: description,
                        type: type,
                        location: location,
                        imageURL: imageURL,
                        isBrizPick: isBrizPick
                    )
                }
            }
    }

    func loadMoreListings() {
        // If we're already loading or there are no more listings, return
        if isLoadingMoreListings || !hasMoreListings || lastDocument == nil {
            return
        }
        
        isLoadingMoreListings = true
        
        // Create query for next batch
        db.collection("listings")
            .order(by: "name")
            .limit(to: pageSize)
            .start(afterDocument: lastDocument!)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoadingMoreListings = false
                
                if let error = error {
                    self.errorMessage = "Error loading more listings: \(error.localizedDescription)"
                    self.showError = true
                    print("❌ Error loading more listings: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // No more documents to load
                    self.hasMoreListings = false
                    return
                }
                
                // Save the last document for pagination
                self.lastDocument = documents.last
                
                // Check if we've reached the end
                if documents.count < self.pageSize {
                    self.hasMoreListings = false
                }
                
                // Manual decoding
                let newListings = documents.compactMap { document -> Listing? in
                    let data = document.data()
                    let id = document.documentID
                    
                    // Check if all required fields exist
                    guard 
                        let name = data["name"] as? String,
                        let category = data["category"] as? String,
                        let description = data["description"] as? String,
                        let type = data["type"] as? String,
                        let location = data["location"] as? String
                    else {
                        print("❌ Skipping document \(id) due to missing required fields")
                        return nil
                    }
                    
                    let imageURL = data["imageURL"] as? String
                    let isBrizPick = data["isBrizPick"] as? Bool
                    
                    return Listing(
                        id: id,
                        name: name,
                        category: category,
                        description: description,
                        type: type,
                        location: location,
                        imageURL: imageURL,
                        isBrizPick: isBrizPick
                    )
                }
                
                // Append new listings to existing ones
                self.listings.append(contentsOf: newListings)
            }
    }

    // Add Listings
    
    func addListing(name: String, category: String, description: String, type: String, location: String, isBrizPick: Bool? = nil) {
        // Create a new listing with the provided data
        let newListingRef = db.collection("listings").document()
        let newListingId = newListingRef.documentID
        
        let newListing = Listing(
            id: newListingId,
            name: name,
            category: category,
            description: description,
            type: type,
            location: location,
            isBrizPick: isBrizPick
        )
        
        // Manual encoding
        var data: [String: Any] = [
            "name": newListing.name,
            "category": newListing.category,
            "description": newListing.description,
            "type": newListing.type,
            "location": newListing.location
        ]
        
        // Only add isBrizPick to the data if it's not nil
        if let isBrizPick = newListing.isBrizPick {
            data["isBrizPick"] = isBrizPick
        }
        
        // Add to Firestore
        newListingRef.setData(data) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "Error adding listing: \(error.localizedDescription)"
                self.showError = true
                print("❌ Error adding listing: \(error)")
            }
        }
    }

    // Update Listings
    
    func updateListing(listing: Listing) {
        guard let id = listing.id else {
            errorMessage = "Error updating listing: Missing ID"
            showError = true
            return
        }
        
        // Manual encoding
        var data: [String: Any] = [
            "name": listing.name,
            "category": listing.category,
            "description": listing.description,
            "type": listing.type,
            "location": listing.location
        ]
        
        // Only add isBrizPick to the data if it's not nil
        if let isBrizPick = listing.isBrizPick {
            data["isBrizPick"] = isBrizPick
        }
        
        db.collection("listings").document(id).updateData(data) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "Error updating listing: \(error.localizedDescription)"
                self.showError = true
                print("❌ Error updating listing: \(error)")
            }
        }
    }

    // Delete Listings
    
    func deleteListing(listing: Listing) {
        // Safely unwrap the optional id
        guard let documentId = listing.id else {
            self.errorMessage = "Error deleting listing: Missing document ID"
            self.showError = true
            print("❌ Error deleting listing: Missing document ID")
            return
        }
        
        db.collection("listings").document(documentId).delete { error in
            if let error = error {
                self.errorMessage = "Error deleting listing: \(error.localizedDescription)"
                self.showError = true
                print("❌ Error deleting listing: \(error)")
            }
        }
    }
}
//
//  brizlist_test1App.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI
import Firebase

@main
struct BrizlistApp: App {
    // This connects your AppDelegate to the SwiftUI lifecycle
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
//
//  Listing.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore

struct Listing: Identifiable, Codable {
    @DocumentID var id: String? // Changed from String to String? to prevent warnings
    var name: String
    var category: String
    var description: String
    var rating: Double
    var type: String = "Standard"
}
//
//  Listing.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore

struct Listing: Identifiable, Codable {
    @DocumentID var id: String? // Optional because Firebase generates this automatically
    var name: String
    var category: String
    var description: String
    var type: String
    var location: String
    var imageURL: String? // Optional because not all listings need images
    var isBrizPick: Bool?
    
    // Updated initializer with consistent required/optional parameters
    init(id: String? = nil, name: String, category: String, description: String, type: String, location: String, imageURL: String? = nil, isBrizPick: Bool? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.type = type
        self.location = location
        self.imageURL = imageURL
        self.isBrizPick = isBrizPick
    }
}
//
//  RefreshControl.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 17/03/2025.
//

import Foundation
import SwiftUI

struct RefreshControl: View {
    var coordinateSpace: CoordinateSpace
    var onRefresh: () -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: coordinateSpace).midY > 50 {
                Spacer()
                    .onAppear {
                        if !isRefreshing {
                            isRefreshing = true
                            onRefresh()
                        }
                    }
                    .onDisappear {
                        isRefreshing = false
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                }
                Spacer()
            }
            .offset(y: max(0, geometry.frame(in: coordinateSpace).midY - 30))
        }
        .padding(.top, -50)
        .frame(height: 0)
    }
}
//
//  AddListingView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import SwiftUI

struct AddListingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ListingsViewModel
    
    @State private var name = ""
    @State private var category = ""
    @State private var description = ""
    @State private var rating: Double = 3.0
    @State private var type = ""
    @State private var location = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Listing Details")) {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Description", text: $description)
                    TextField("Type", text: $type)
                    TextField("Location", text: $location)
                }
                
                Button("Save") {
                    viewModel.addListing(
                        name: name,
                        category: category,
                        description: description,
                        type: type,
                        location: location
                    )
                    dismiss()
                }
                .disabled(name.isEmpty || category.isEmpty)
            }
            .navigationTitle("Add Listing")
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
//
//  ListingStyling.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 18/03/2025.
//

import Foundation
import SwiftUI

struct ListingStyling {
    
    // MARK: - Category Styling
    
    static func categoryTextView(_ category: String) -> some View {
        let color: Color
        
        // Determine color based on category
        switch category.lowercased() {
        case "restaurant":
            color = .orange
        case "pub":
            color = .brown
        case "coffee shop":
            color = .blue
        case "bar":
            color = .purple
        default:
            color = .gray
        }
        
        // Return the styled text view with tag icon
        return HStack(spacing: 4) {
            Image(systemName: "tag.fill")
                .font(.caption)
            
            Text(category)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(6)
    }
    
    
    // MARK: - Type Styling
    
    static func typeTextView(_ type: String) -> some View {
        let color: Color
        
        // Determine color based on type
        switch type.lowercased() {
        case "fine dining":
            color = .red
        case "gastro":
            color = .green
        case "casual":
            color = .blue
        default:
            color = .gray
        }
        
        // Return the styled text view
        return Text(type)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }

    // MARK: - Location Styling
    
    static func locationTextView(_ location: String) -> some View {
        Text(location)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.teal)
            .cornerRadius(6)
    }


    // Single function that handles all location styling
    static func categoryLocationView(_ location: String) -> some View {
        let color: Color
        
        // Determine color based on location
        switch location.lowercased() {
        case "clifton":
            color = .orange
        case "redcliffe":
            color = .brown
        case "bedminster":
            color = .blue
        case "city centre":
            color = .purple
        default:
            color = .gray
        }
        
        // Return the styled text view with pin icon
        return HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.caption)
            
            Text(location)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(6)
    }
}
//
//  ListingDetailView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with name
                Text(listing.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Type and category pills
                HStack(spacing: 10) {
                    Text(listing.type)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorForType(listing.type))
                        .cornerRadius(8)
                    
                    Text(listing.category)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorForCategory(listing.category))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(listing.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Listing Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper functions for colors (same as in ListingCardView)
    private func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "restaurant":
            return .red
        case "cafe":
            return .orange
        case "bar":
            return .purple
        default:
            return .blue
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "premium":
            return .yellow
        case "featured":
            return .green
        default:
            return .gray
        }
    }
}
//
//  EditListingView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import SwiftUI

struct EditListingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ListingsViewModel
    var listing: Listing
    
    @State private var name: String
    @State private var category: String
    @State private var description: String
    @State private var type: String
    @State private var location: String
    
    init(viewModel: ListingsViewModel, listing: Listing) {
        self.viewModel = viewModel
        self.listing = listing
        _name = State(initialValue: listing.name)
        _category = State(initialValue: listing.category)
        _description = State(initialValue: listing.description)
        _type = State(initialValue: listing.type)
        _location = State(initialValue: listing.location)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Listing Details")) {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Description", text: $description)
                    TextField("Type", text: $type)
                    TextField("Location", text: $location)                  
                }
                
                Button("Update") {
                    var updatedListing = listing
                    updatedListing.name = name
                    updatedListing.category = category
                    updatedListing.description = description
                    updatedListing.type = type
                    updatedListing.location = location
                    viewModel.updateListing(listing: updatedListing)
                    dismiss()
                }
                .disabled(name.isEmpty || category.isEmpty)
            }
            .navigationTitle("Edit Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Computed property to check if form is valid
    private var isFormInvalid: Bool {
        name.isEmpty || 
        category.isEmpty || 
        description.isEmpty || 
        type.isEmpty || 
        location.isEmpty
    }
}
//
//  ListingCardView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    let onEdit: (Listing) -> Void
    let onDelete: (Listing) -> Void
    @State private var showingDetailView = false
    
    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            // Simple white card
            VStack(alignment: .leading, spacing: 8) {
                // Name and category
                HStack {
                    // Name
                    Text(listing.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer ()

                    // Location
                    ListingStyling.categoryLocationView(listing.location)

                    // Category
                    ListingStyling.categoryTextView(listing.category)
                }

                // Divider line
                Divider()
                    .padding(.top, 2)
                    .padding(.bottom, 4)

                // Description
                if !listing.description.isEmpty {
                    Text(listing.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Footer with rating, type and edit button
                HStack {
                    
                    // Type
                    ListingStyling.typeTextView(listing.type)
                    
                    Spacer()
                    
                    // Edit button
                    Button(action: {
                        onEdit(listing)
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .frame(height: 180)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                onEdit(listing)
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                onDelete(listing)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDetailView) {
            NavigationView {
                ListingDetailView(listing: listing)
            }
        }
    }
}
//
//  HeaderView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 16/03/2025.
//

import Foundation
import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Background color for status bar area
            Color(.systemGray6)  // Light gray color that matches scroll areas
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
            
            // Header content
            HStack {
                Text("Brizlist")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Optional header actions can be added here
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))  // Same light gray color
            
            // Bottom border line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

#Preview {
    HeaderView()
}
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
    @State private var showingAddListing = false
    @State private var listingToEdit: Listing?
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Add the HeaderView at the top
                HeaderView()

                // Main scroll view
                ScrollView {
                    RefreshControl(coordinateSpace: .named("refresh")) {
                        viewModel.fetchListings()
                    }
                    
                    LazyVStack(spacing: 16) {
                        // Individual listing cards
                        ForEach(viewModel.listings) { listing in
                            ListingCardView(
                                listing: listing,
                                onEdit: { listingToEdit = $0 },
                                onDelete: { viewModel.deleteListing(listing: $0) }
                            )
                            .padding(.horizontal)
                            .buttonStyle(PlainButtonStyle())
                            .navigationBarHidden(true)
                            // Load more when reaching the last few items
                            .onAppear {
                                if listing.id == viewModel.listings.last?.id {
                                    viewModel.loadMoreListings()
                                }
                            }
                        }
                        
                        // Loading indicator at the bottom
                        if viewModel.isLoadingMoreListings {
                            ProgressView()
                                .padding()
                        }
                        
                        // Message when no more listings
                        if !viewModel.hasMoreListings && !viewModel.listings.isEmpty {
                            Text("No more listings to load")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 80) // Add padding at bottom to avoid toolbar overlap
                }
            }
            
            // Floating add button at bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingAddListing = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            viewModel.fetchListings()
        }
        .sheet(isPresented: $showingAddListing) {
            AddListingView(viewModel: viewModel)
        }
        .sheet(item: $listingToEdit) { listing in
            EditListingView(viewModel: viewModel, listing: listing)
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") {
                viewModel.showError = false
            }
        } message: { errorMessage in
            Text(errorMessage)
        }
        .coordinateSpace(name: "refresh")
    }
}

#Preview {
    ContentView()
}
//
//  AppDelegate.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import UIKit
import SwiftUI
import FirebaseCore
import os.log
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Disable all system logging
        if #available(iOS 14.0, *) {
            // Firebase logs can't be directly controlled via OSLog in this way
            // We'll rely on Firebase's own logging configuration instead
        }
        
        // Set Firebase log level to reduce logs
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        
        // Configure Firebase without App Check for development
        FirebaseApp.configure()
        
        // Configure Firestore caching
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
        
        return true
    }
}