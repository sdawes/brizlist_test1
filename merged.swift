//
//  ListingsViewModel.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 14/03/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

/// ViewModel responsible for managing Listing data and Firestore interactions
class ListingsViewModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var listings: [Listing] = []
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreListings = true
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let db = Firestore.firestore()
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    private var listener: ListenerRegistration?
    
    struct FilterOption {
        let field: String      // Firestore field name (e.g., "isBrizPick")
        let displayName: String // UI display name (e.g., "Briz Picks")
    }
    
    // Dictionary to track which filters are active
    @Published var activeFilterValues: [String: Bool] = [:]
    
    // List of available filters (for UI and reference)
    let availableFilters: [FilterOption] = [
        FilterOption(field: "isBrizPick", displayName: "Briz Picks"),
        FilterOption(field: "isSundayLunch", displayName: "Sunday Lunch"),
        FilterOption(field: "isVegan", displayName: "Vegan Friendly"),
        FilterOption(field: "isDog", displayName: "Dog Friendly"),
        // Add more filters as needed
    ]
    
    init() {
        // Initialize all filters to false (inactive)
        for filter in availableFilters {
            activeFilterValues[filter.field] = false
        }
        listenForListings()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Public Methods
    // ================================

    public func fetchListings() {
        resetPaginationState()
        fetchData(query: createBaseQuery(), isInitialFetch: true)
    }
    
    public func loadMoreListings() {
        guard canLoadMore, let lastDoc = lastDocument else { return }
        isLoadingMore = true
        
        let query = db.collection("listings")
            .order(by: "name")
            .start(afterDocument: lastDoc)
            .limit(to: pageSize)
            
        fetchData(query: query, isInitialFetch: false)
    }
    
    func addListing(_ listing: Listing) {
        db.collection("listings").document().setData(
            createListingData(from: listing)
        ) { [weak self] error in
            self?.handleFirestoreError(error, message: "Error adding listing")
        }
    }
    
    func updateListing(_ listing: Listing) {
        guard let id = listing.id else {
            handleFirestoreError(NSError(domain: "", code: -1), message: "Missing listing ID")
            return
        }
        
        db.collection("listings").document(id).updateData(
            createListingData(from: listing)
        ) { [weak self] error in
            self?.handleFirestoreError(error, message: "Error updating listing")
        }
    }
    
    func deleteListing(_ listing: Listing) {
        guard let id = listing.id else {
            handleFirestoreError(NSError(domain: "", code: -1), message: "Missing listing ID")
            return
        }
        
        db.collection("listings").document(id).delete { [weak self] error in
            self?.handleFirestoreError(error, message: "Error deleting listing")
        }
    }

    // Helper to check if any filters are active
    var hasActiveFilters: Bool {
        activeFilterValues.values.contains(true)
    }
    
    // MARK: - Private Helpers
    // ================================

    private var canLoadMore: Bool {
        !isLoadingMore && hasMoreListings && lastDocument != nil
    }
    
    private func createBaseQuery() -> Query {
        var query = db.collection("listings").order(by: "name")
        
        // Apply all active filters
        for (field, isActive) in activeFilterValues {
            if isActive {
                query = query.whereField(field, isEqualTo: true)
            }
        }
        
        return query.limit(to: pageSize)
    }
    
    private func resetPaginationState() {
        listings = []
        lastDocument = nil
        hasMoreListings = true
    }
    
    private func listenForListings() {
        listener = createBaseQuery().addSnapshotListener { [weak self] snapshot, error in
            self?.processQueryResults(snapshot: snapshot, error: error, isInitialFetch: true)
        }
    }
    
    private func fetchData(query: Query, isInitialFetch: Bool) {
        isLoadingMore = !isInitialFetch
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            defer { self.isLoadingMore = false }
            
            self.processQueryResults(snapshot: snapshot, error: error, isInitialFetch: isInitialFetch)
        }
    }
    
    private func processQueryResults(snapshot: QuerySnapshot?, error: Error?, isInitialFetch: Bool) {
        if let error = error {
            handleFirestoreError(error, message: "Error fetching listings")
            return
        }
        
        guard let documents = snapshot?.documents, !documents.isEmpty else {
            hasMoreListings = false
            if isInitialFetch {
                listings = []
            }
            return
        }
        
        lastDocument = documents.last
        hasMoreListings = documents.count >= pageSize
        
        let newListings = documents.compactMap(createListingFromDocument)
        
        if isInitialFetch {
            listings = newListings
        } else {
            listings.append(contentsOf: newListings)
        }
    }
    
    private func createListingFromDocument(_ document: QueryDocumentSnapshot) -> Listing? {
        let data = document.data()
        return Listing(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            category: data["category"] as? String ?? "",
            description: data["description"] as? String ?? "",
            location: data["location"] as? String ?? "",
            isBrizPick: data["isBrizPick"] as? Bool,
            isVegan: data["isVegan"] as? Bool,
            isVeg: data["isVeg"] as? Bool,
            isDog: data["isDog"] as? Bool,
            isChild: data["isChild"] as? Bool,
            isSundayLunch: data["isSundayLunch"] as? Bool
        )
    }
    
    private func createListingData(from listing: Listing) -> [String: Any] {
        var data: [String: Any] = [
            "name": listing.name,
            "category": listing.category,
            "description": listing.description,
            "location": listing.location
        ]
        
        if let isBrizPick = listing.isBrizPick { data["isBrizPick"] = isBrizPick }
        if let isVegan = listing.isVegan { data["isVegan"] = isVegan }
        if let isVeg = listing.isVeg { data["isVeg"] = isVeg }
        if let isDog = listing.isDog { data["isDog"] = isDog }
        if let isChild = listing.isChild { data["isChild"] = isChild }
        if let isSundayLunch = listing.isSundayLunch { data["isSundayLunch"] = isSundayLunch }
        
        return data
    }
    
    private func handleFirestoreError(_ error: Error?, message: String) {
        if let error = error {
            errorMessage = "\(message): \(error.localizedDescription)"
            showError = true
            print("❌ \(message): \(error)")
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
import FirebaseCore
import FirebaseFirestore

@main
struct BrizlistApp: App {
    // Initialize Firebase when the app starts
    init() {
        // Configure Firebase for Firestore and Storage access
        FirebaseApp.configure()
        
        // Reduce Firebase console logs to errors only (keeps Xcode output clean)
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        
        // Set up Firestore with offline persistence
        let settings = FirestoreSettings()
        
        // Use a default PersistentCacheSettings instance to enable offline persistence
        // This avoids the newBuilder() error in Firebase 11.9
        // Note: This uses the default cache size (100 MB) instead of unlimited
        // This allows your app to work offline and load listings faster
        settings.cacheSettings = PersistentCacheSettings()
        
        // Apply the settings to Firestore
        Firestore.firestore().settings = settings
        
        // Debug: Confirm Firebase SDK version
        print("Firebase SDK Version: \(FirebaseVersion())")
    }
    
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
    @DocumentID var id: String? // Optional because Firebase generates this automatically
    var name: String
    var category: String
    var description: String
    var location: String
    var isBrizPick: Bool?
    var isVegan: Bool?
    var isVeg: Bool?
    var isDog: Bool?
    var isChild: Bool?
    var isSundayLunch: Bool?
    
    // Updated initializer with consistent required/optional parameters
    init(id: String? = nil, name: String, category: String, description: String, location: String, isBrizPick: Bool? = nil, isVegan: Bool? = nil, isVeg: Bool? = nil, isDog: Bool? = nil, isChild: Bool? = nil, isSundayLunch: Bool? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.location = location
        self.isBrizPick = isBrizPick
        self.isVegan = isVegan
        self.isVeg = isVeg
        self.isDog = isDog
        self.isChild = isChild
        self.isSundayLunch = isSundayLunch
    }
}
//
//  FormValidator.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/04/2025.
//

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
                
                Text("Use our data driven  symbols to find places that match your needs, whether you're looking for vegan options, child-friendly spaces, or our special Briz Picks!")
                    .font(.caption)
                
                Divider()
                
                Text("Symbol Guide")
                    .font(.title3.bold())
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.black)
                            .font(.caption)
                            .frame(width: 20, alignment: .center)
                        Text("Vegan Options")
                            .font(.caption)
                    }
                    
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
    @State private var location = ""
    @State private var isVegan: Bool = false
    @State private var isVeg: Bool = false
    @State private var isDog: Bool = false
    @State private var isChild: Bool = false
    @State private var isBrizPick: Bool = false
    @State private var isSundayLunch: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Listing Details")) {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                }

                Section(header: Text("Features")) {
                    Toggle("Vegan Friendly", isOn: $isVegan)
                    Toggle("Vegetarian Friendly", isOn: $isVeg)
                    Toggle("Dog Friendly", isOn: $isDog)
                    Toggle("Child Friendly", isOn: $isChild)
                    Toggle("Briz Pick", isOn: $isBrizPick)
                    Toggle("Sunday Lunch", isOn: $isSundayLunch)
                }
                
                Section {
                    Button(action: {
                        let newListing = Listing(
                            name: name,
                            category: category,
                            description: description,
                            location: location,
                            isBrizPick: isBrizPick,
                            isVegan: isVegan,
                            isVeg: isVeg,
                            isDog: isDog,
                            isChild: isChild,
                            isSundayLunch: isSundayLunch
                        )
                        viewModel.addListing(newListing)
                        dismiss()
                    }) {
                        Text("Save")
                    }
                    .disabled(name.isEmpty || category.isEmpty || description.isEmpty || location.isEmpty)
                }
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
        Text(category.lowercased())
            .font(.caption)
            .foregroundColor(.black)
    }
    
    

    // MARK: - Location Styling
    
    static func locationTextView(_ location: String) -> some View {
        Text(location.lowercased())
            .font(.caption)
            .foregroundColor(.black)
    }


    // MARK: - BrizPick Styling
    
    static func brizPickBadge() -> some View {
        HStack(spacing: 4) {
            // Enhanced rainbow gradient star
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Briz Pick text in black
            Text("Briz Pick")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
    }

    // MARK: - BrizPick Star Styling
    
    static func brizPickStar() -> some View {
        Image(systemName: "star.fill")
            .font(.caption)
            .foregroundColor(.red) // Standard system red
    }

    // MARK: - BrizPick Custom Symbol
    
    static func brizPickCustomSymbol() -> some View {
        Image(systemName: "star.fill")
            .font(.caption)
            .foregroundColor(.black)
    }

    // MARK: - Amenity Symbols
    
    static func veganSymbol() -> some View {
        Image(systemName: "carrot.fill")
            .font(.caption)
    }
    
    static func vegSymbol() -> some View {
        Image(systemName: "leaf.fill")
            .font(.caption)
    }
    
    static func dogSymbol() -> some View {
        Image(systemName: "pawprint.fill")
            .font(.caption)
    }
    
    static func childSymbol() -> some View {
        Image(systemName: "figure.2.and.child.holdinghands")
            .font(.caption)
    }

    // MARK: - Sunday Lunch Symbol
    
    static func sundayLunchSymbol() -> some View {
        Image(systemName: "fork.knife")
            .font(.caption)
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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(listing.name)
                    .font(.title3.bold())
                
                Text("A beloved local spot that's been serving Bristol for years. Known for their exceptional service and welcoming atmosphere, this place has become a cornerstone of the community.")
                    .font(.caption)
                
                Text("Whether you're stopping by for a quick visit or settling in for a longer stay, you'll find yourself surrounded by the warm, authentic vibe that makes Bristol's food scene so special.")
                    .font(.caption)
                
                Text("Make sure to check out their seasonal specials and don't forget to ask about their house recommendations!")
                    .font(.caption)
                
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
                
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ListingDetailView(listing: Listing(
        id: "1",
        name: "The Bristol Lounge",
        category: "Restaurant",
        description: "A cozy spot in the heart of Bristol",
        location: "Clifton, Bristol"
    ))
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
    @State private var location: String
    @State private var isVegan: Bool
    @State private var isVeg: Bool
    @State private var isDog: Bool
    @State private var isChild: Bool
    @State private var isBrizPick: Bool
    @State private var isSundayLunch: Bool
    
    init(viewModel: ListingsViewModel, listing: Listing) {
        self.viewModel = viewModel
        self.listing = listing
        _name = State(initialValue: listing.name)
        _category = State(initialValue: listing.category)
        _description = State(initialValue: listing.description)
        _location = State(initialValue: listing.location)
        _isVegan = State(initialValue: listing.isVegan ?? false)
        _isVeg = State(initialValue: listing.isVeg ?? false)
        _isDog = State(initialValue: listing.isDog ?? false)
        _isChild = State(initialValue: listing.isChild ?? false)
        _isBrizPick = State(initialValue: listing.isBrizPick ?? false)
        _isSundayLunch = State(initialValue: listing.isSundayLunch ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Listing Details")) {
                    TextField("Name of business", text: $name)
                    TextField("Category", text: $category)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                }

                Section(header: Text("Features")) {
                    Toggle("Vegan Friendly", isOn: $isVegan)
                    Toggle("Vegetarian Friendly", isOn: $isVeg)
                    Toggle("Dog Friendly", isOn: $isDog)
                    Toggle("Child Friendly", isOn: $isChild)
                    Toggle("Briz Pick", isOn: $isBrizPick)
                    Toggle("Sunday Lunch", isOn: $isSundayLunch)
                }
                
                Button("Update") {
                    var updatedListing = listing
                    updatedListing.name = name
                    updatedListing.category = category
                    updatedListing.description = description
                    updatedListing.location = location
                    updatedListing.isVegan = isVegan
                    updatedListing.isVeg = isVeg
                    updatedListing.isDog = isDog
                    updatedListing.isChild = isChild
                    updatedListing.isBrizPick = isBrizPick
                    updatedListing.isSundayLunch = isSundayLunch
                    viewModel.updateListing(updatedListing)
                    dismiss()
                }
                .disabled(name.isEmpty || category.isEmpty || description.isEmpty || location.isEmpty)
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
                HStack {
                    Text(listing.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    // Briz Pick star right next to name
                    if listing.isBrizPick ?? false {
                        ListingStyling.brizPickCustomSymbol()
                    }
                    
                    Spacer()
                    
                    // Other amenity symbols
                    HStack(spacing: 4) {
                        if listing.isVegan ?? false {
                            ListingStyling.veganSymbol()
                                .foregroundColor(.black) 
                        }
                        if listing.isVeg ?? false {
                            ListingStyling.vegSymbol()
                                .foregroundColor(.black)
                        }
                        if listing.isDog ?? false {
                            ListingStyling.dogSymbol()
                                .foregroundColor(.black)
                        }
                        if listing.isChild ?? false {
                            ListingStyling.childSymbol()
                                .foregroundColor(.black)
                        }
                        if listing.isSundayLunch ?? false {
                            ListingStyling.sundayLunchSymbol()
                                .foregroundColor(.black)
                        }
                    }
                }
                
                // Divider line
                Divider()
                    .padding(.top, 2)
                    .padding(.bottom, 4)

                // Add description back
                if !listing.description.isEmpty {
                    Text(listing.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

            
                
                Spacer()
                
                // Footer with rating, type and edit button
                HStack {
                    
                // Category
                ListingStyling.categoryTextView(listing.category)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ListingStyling.locationTextView(listing.location)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
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
            .frame(height: 160)
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
            .presentationDragIndicator(.visible)
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
    @ObservedObject var viewModel: ListingsViewModel
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

                if viewModel.hasActiveFilters {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        let count = viewModel.activeFilterValues.values.filter { $0 }.count
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

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
            FilterSheetView(viewModel: viewModel)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $showingAboutSheet, content: {
            AboutSheetView()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        })
    }
}

#Preview {
    HeaderView(viewModel: ListingsViewModel())
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
            // Color(.systemGroupedBackground)
            Color(red: 0.95, green: 0.95, blue: 0.97)
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                HeaderView(viewModel: viewModel)
                ListingsScrollView(viewModel: viewModel, listingToEdit: $listingToEdit)
            }
            
            // Floating add button
            FloatingAddButton(showingAddListing: $showingAddListing)
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
    }
}

// Extracted ScrollView into a separate view
struct ListingsScrollView: View {
    @ObservedObject var viewModel: ListingsViewModel
    @Binding var listingToEdit: Listing?
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("refresh")) {
                viewModel.fetchListings()
            }
            
            LazyVStack(spacing: 16) {
                ForEach(viewModel.listings) { listing in
                    ListingCardView(
                        listing: listing,
                        onEdit: { listingToEdit = $0 },
                        onDelete: { viewModel.deleteListing($0) }
                    )
                    .padding(.horizontal)
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if listing.id == viewModel.listings.last?.id {
                            viewModel.loadMoreListings()
                        }
                    }
                }
                
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
                
                if !viewModel.hasMoreListings && !viewModel.listings.isEmpty {
                    Text("No more listings to load")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.top)
            .padding(.bottom, 80)
        }
        .coordinateSpace(name: "refresh")
    }
}

// Extracted Floating Add Button
struct FloatingAddButton: View {
    @Binding var showingAddListing: Bool
    
    var body: some View {
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
}

#Preview {
    ContentView()
}
//
//  FilterSheetView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 29/03/2025.
//

import Foundation
import SwiftUI

struct FilterSheetView: View {
    @ObservedObject var viewModel: ListingsViewModel
    @Environment(\.dismiss) var dismiss
    
    // Local copy of filters for preview/editing
    @State private var localFilters: [String: Bool] = [:]
    
    // Initialize with current filters
    init(viewModel: ListingsViewModel) {
        self.viewModel = viewModel
        
        // Make a copy of the current filter values
        var initialFilters: [String: Bool] = [:]
        for filter in viewModel.availableFilters {
            initialFilters[filter.field] = viewModel.activeFilterValues[filter.field] ?? false
        }
        self._localFilters = State(initialValue: initialFilters)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filter By")) {
                    // Create a toggle for each available filter
                    ForEach(viewModel.availableFilters, id: \.field) { filter in
                        Toggle(filter.displayName, isOn: Binding(
                            get: { localFilters[filter.field] ?? false },
                            set: { localFilters[filter.field] = $0 }
                        ))
                    }
                }
                
                Section {
                    // Apply button applies all filters at once
                    Button("Apply Filters") {
                        // Update the view model with our local changes
                        for filter in viewModel.availableFilters {
                            viewModel.activeFilterValues[filter.field] = localFilters[filter.field] ?? false
                        }
                        viewModel.fetchListings()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    // Clear all button
                    Button("Clear All Filters") {
                        for filter in viewModel.availableFilters {
                            localFilters[filter.field] = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}