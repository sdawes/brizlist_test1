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
    @Published private(set) var featuredListings: [Listing] = []
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreListings = true
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var selectedTags: Set<String> = []
    @Published var noResultsFromFiltering: Bool = false
    
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
        FilterOption(field: "isDog", displayName: "Dog Friendly"),
        FilterOption(field: "isFeatured", displayName: "Featured"),
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
    
    // Helper to check if any filters are active
    var hasActiveFilters: Bool {
        activeFilterValues.values.contains(true)
    }
    
    // Add this helper property to check if tag filtering is active
    var hasTagFilters: Bool {
        return !selectedTags.isEmpty
    }
    
    // MARK: - Private Helpers
    // ================================

    private var canLoadMore: Bool {
        !isLoadingMore && hasMoreListings && lastDocument != nil
    }
    
    private func createBaseQuery() -> Query {
        // Start with CollectionReference and then convert to Query
        let collectionRef = db.collection("listings")
        var query: Query = collectionRef.order(by: "name")
        
        // Filter by tags if any are selected
        if !selectedTags.isEmpty {
            // For "AND" tag filtering, we need to check that each document contains all selected tags
            // We'll use multiple array-contains queries in combination with filter client-side
            
            // Start with the first tag (we need at least one in the Firestore query)
            let tagsArray = Array(selectedTags)
            query = query.whereField("tags", arrayContains: tagsArray[0])
            
            // We'll need to filter the rest of the tags client-side in processQueryResults
        }
        
        // Apply all other active filters (your existing code)
        for (field, isActive) in activeFilterValues {
            if isActive {
                query = query.whereField(field, isEqualTo: true)
            }
        }
        
        return query.limit(to: pageSize)
    }
    
    private func resetPaginationState() {
        listings = []
        featuredListings = []
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
        
        // Check if we have any filters active 
        let hasActiveFilters = self.hasActiveFilters || self.hasTagFilters
        
        guard let documents = snapshot?.documents else {
            hasMoreListings = false
            if isInitialFetch {
                listings = []
                featuredListings = []
                
                // Set the noResultsFromFiltering flag if we have filters but no results
                noResultsFromFiltering = hasActiveFilters
            }
            return
        }
        
        // Additional client-side filtering if we have multiple tags
        // (Firestore can only query for one array-contains at a time)
        var filteredDocuments = documents
        if selectedTags.count > 1 {
            let allTags = Array(selectedTags)
            // Skip the first tag as it was already filtered in the query
            let additionalTags = allTags.dropFirst()
            
            // Filter documents to contain ALL the selected tags (AND operation)
            filteredDocuments = documents.filter { document in
                guard let documentTags = document.data()["tags"] as? [String] else {
                    return false
                }
                
                // Check that all additional tags are present in the document
                for tag in additionalTags {
                    if !documentTags.contains(tag) {
                        return false
                    }
                }
                return true
            }
        }
        
        // Check if we have results after client-side filtering
        if filteredDocuments.isEmpty {
            hasMoreListings = false
            if isInitialFetch {
                listings = []
                featuredListings = []
                
                // Set the noResultsFromFiltering flag
                noResultsFromFiltering = hasActiveFilters
            }
            return
        }
        
        // Found results, so reset the no results flag
        noResultsFromFiltering = false
        
        lastDocument = documents.last // Keep the original last document for pagination
        hasMoreListings = documents.count >= pageSize
        
        let newListings = filteredDocuments.compactMap(createListingFromDocument)
        
        let (featured, regular) = separateFeaturedListings(newListings)
        
        if isInitialFetch {
            featuredListings = featured
            listings = regular
        } else {
            featuredListings.append(contentsOf: featured)
            listings.append(contentsOf: regular)
        }
    }
    
    private func createListingFromDocument(_ document: QueryDocumentSnapshot) -> Listing? {
        let data = document.data()
        
        return Listing(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            tags: data["tags"] as? [String] ?? [],
            cuisine: data["cuisine"] as? String ?? "",
            description: data["description"] as? String ?? "",
            location: data["location"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            isBrizPick: data["isBrizPick"] as? Bool,
            isVeg: data["isVeg"] as? Bool,
            isDog: data["isDog"] as? Bool,
            isChild: data["isChild"] as? Bool,
            isSundayLunch: data["isSundayLunch"] as? Bool,
            isFeatured: data["isFeatured"] as? Bool
        )
    }
    
    private func handleFirestoreError(_ error: Error?, message: String) {
        if let error = error {
            errorMessage = "\(message): \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func separateFeaturedListings(_ listings: [Listing]) -> (featured: [Listing], regular: [Listing]) {
        var featured: [Listing] = []
        var regular: [Listing] = []
        
        for listing in listings {
            if listing.isFeatured == true {
                featured.append(listing)
            } else {
                regular.append(listing)
            }
        }
        
        return (featured, regular)
    }
    
    // Add these methods to manage tag selection
    func selectTag(_ tag: String) {
        selectedTags.insert(tag)
        fetchListings() // Refresh listings with the new filter
    }

    func deselectTag(_ tag: String) {
        selectedTags.remove(tag)
        fetchListings() // Refresh listings with the new filter
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        fetchListings() // Refresh listings with the new filter
    }

    func clearTagFilters() {
        selectedTags.removeAll()
        fetchListings() // Refresh listings with the new filter
    }

    // You can also add this method to get all unique tags from current listings
    func getAllUniqueTags() -> [String] {
        var allTags = Set<String>()
        
        // Collect tags from all listings
        for listing in listings {
            allTags.formUnion(listing.tags)
        }
        
        for listing in featuredListings {
            allTags.formUnion(listing.tags)
        }
        
        return Array(allTags).sorted()
    }

    // Add a new method to check if a filter combination would yield results
    func wouldFiltersYieldResults(tags: Set<String>, amenities: [String: Bool]) -> Bool {
        // If no filters selected, we'll have results
        if tags.isEmpty && !amenities.values.contains(true) {
            return true
        }
        
        // Create a base query - start with CollectionReference and then convert to Query
        let collectionRef = db.collection("listings")
        var query: Query = collectionRef
        
        // Apply amenity filters (AND operation - must match all)
        for (field, isActive) in amenities {
            if isActive {
                query = query.whereField(field, isEqualTo: true)
            }
        }
        
        // For tags, we need to handle the AND operation differently
        // We'll do the first tag in Firestore and the rest client-side
        if !tags.isEmpty {
            let tagsArray = Array(tags)
            query = query.whereField("tags", arrayContains: tagsArray[0])
        }
        
        // Use a semaphore to make this synchronous
        let semaphore = DispatchSemaphore(value: 0)
        var hasResults = false
        
        query.limit(to: 20).getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                // If we have multiple tags, filter client-side to ensure all tags match
                if tags.count > 1 {
                    let allTags = Array(tags)
                    let additionalTags = allTags.dropFirst() // Skip first tag (already filtered)
                    
                    // Check for documents with ALL the selected tags
                    let matchingDocs = documents.filter { document in
                        guard let documentTags = document.data()["tags"] as? [String] else {
                            return false
                        }
                        
                        // Document must contain ALL additional tags
                        for tag in additionalTags {
                            if !documentTags.contains(tag) {
                                return false
                            }
                        }
                        return true
                    }
                    
                    hasResults = !matchingDocs.isEmpty
                } else {
                    // If just one tag or no tags, the Firestore query is sufficient
                    hasResults = !documents.isEmpty
                }
            }
            semaphore.signal()
        }
        
        // Wait for the result
        _ = semaphore.wait(timeout: .now() + 2.0)
        return hasResults
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
    var tags: [String]
    var cuisine: String // Changed from subCategory to cuisine
    var description: String
    var location: String
    var imageUrl: String? // Changed from imageURL to imageUrl to match Firestore field name
    var isBrizPick: Bool?
    var isVeg: Bool?
    var isDog: Bool?
    var isChild: Bool?
    var isSundayLunch: Bool?
    var isFeatured: Bool?
    
    // Helper to get a displayable URL
    var displayImageUrl: URL? {
        guard let urlString = imageUrl else { return nil }
        return URL(string: urlString)
    }
    
    // Updated initializer with consistent required/optional parameters
    init(id: String? = nil, name: String, tags: [String] = [], cuisine: String = "", description: String, location: String, imageUrl: String? = nil, isBrizPick: Bool? = nil, isVeg: Bool? = nil, isDog: Bool? = nil, isChild: Bool? = nil, isSundayLunch: Bool? = nil, isFeatured: Bool? = nil) {
        self.id = id
        self.name = name
        self.tags = tags
        self.cuisine = cuisine
        self.description = description
        self.location = location
        self.imageUrl = imageUrl
        self.isBrizPick = isBrizPick
        self.isVeg = isVeg
        self.isDog = isDog
        self.isChild = isChild
        self.isSundayLunch = isSundayLunch
        self.isFeatured = isFeatured
    }
}
//
//  ImageCache.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 03/05/2025.
//

import Foundation
import SwiftUI
import Combine

// Helper for file operations outside the actor
class ImageDiskCache {
    static let shared = ImageDiskCache()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Set up persistent cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }
    }
    
    // Get the file URL for a given image URL
    func cacheFileURL(for url: URL) -> URL {
        let fileName = url.absoluteString.hash.description
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    // Load image from disk
    func loadImageFromDisk(for url: URL) -> UIImage? {
        let cacheFileURL = cacheFileURL(for: url)
        
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            return UIImage(data: data)
        } catch {
            print("Error loading image from disk: \(error)")
            return nil
        }
    }
    
    // Save image to disk
    func saveImageToDisk(_ image: UIImage, for url: URL) {
        let cacheFileURL = cacheFileURL(for: url)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        do {
            try data.write(to: cacheFileURL)
        } catch {
            print("Error saving image to disk: \(error)")
        }
    }
    
    // Clean up old cache files (older than 7 days)
    func cleanOldCacheFiles() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey]
            )
            
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            
            for fileURL in fileURLs {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < sevenDaysAgo {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Error cleaning old cache files: \(error)")
        }
    }
    
    // Clear all cached files
    func clearDiskCache() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing image cache: \(error)")
        }
    }
}

actor ImageCacheStore {
    private let cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [URL: Task<UIImage?, Error>] = [:]
    
    init() {
        // Configure NSCache
        cache.countLimit = 100  // Maximum number of cached images
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB limit
    }
    
    func getExistingTask(for url: URL) -> Task<UIImage?, Error>? {
        return loadingTasks[url]
    }
    
    func storeTask(_ task: Task<UIImage?, Error>, for url: URL) {
        loadingTasks[url] = task
    }
    
    func removeTask(for url: URL) {
        loadingTasks[url] = nil
    }
    
    func getFromMemoryCache(for key: NSString) -> UIImage? {
        return cache.object(forKey: key)
    }
    
    func storeInMemoryCache(_ image: UIImage, for key: NSString) {
        cache.setObject(image, forKey: key)
    }
    
    func clearMemoryCache() {
        cache.removeAllObjects()
    }
}

class ImageCache {
    static let shared = ImageCache()
    private let store = ImageCacheStore()
    private let diskCache = ImageDiskCache.shared
    
    private init() {
        // Start cleaning old files
        Task {
            diskCache.cleanOldCacheFiles()
        }
    }
    
    // Get image from cache or load it
    func image(for url: URL) async -> UIImage? {
        // Check memory cache first
        let key = url.absoluteString as NSString
        if let cachedImage = await store.getFromMemoryCache(for: key) {
            print("📂 Using memory cached image for: \(url.absoluteString)")
            return cachedImage
        }
        
        // Check disk cache
        let diskCachedImage = diskCache.loadImageFromDisk(for: url)
        if let diskCachedImage = diskCachedImage {
            print("💾 Using disk cached image for: \(url.absoluteString)")
            // Store in memory cache
            await store.storeInMemoryCache(diskCachedImage, for: key)
            return diskCachedImage
        }
        
        // If task already exists, use that instead of starting a new one
        if let existingTask = await store.getExistingTask(for: url) {
            print("⏳ Using existing download task for: \(url.absoluteString)")
            return try? await existingTask.value
        }
        
        print("🌐 Downloading image from: \(url.absoluteString)")
        
        // Create new download task with retry logic
        let task = Task<UIImage?, Error> {
            defer {
                Task {
                    await store.removeTask(for: url)
                }
            }
            
            // Try up to 3 times with exponential backoff
            for attempt in 1...3 {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    
                    // Check if we got a valid HTTP response
                    if let httpResponse = response as? HTTPURLResponse,
                       !(200...299).contains(httpResponse.statusCode) {
                        print("⚠️ HTTP error \(httpResponse.statusCode) for \(url.absoluteString)")
                        if attempt < 3 {
                            // Wait before retrying (exponential backoff)
                            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                            continue
                        }
                        return nil
                    }
                    
                    guard let image = UIImage(data: data) else {
                        print("❌ Invalid image data received for: \(url.absoluteString)")
                        return nil
                    }
                    
                    print("✅ Successfully downloaded image: \(url.absoluteString)")
                    
                    // Save to memory cache
                    await store.storeInMemoryCache(image, for: key)
                    
                    // Save to disk cache on a background thread
                    Task.detached(priority: .background) {
                        ImageDiskCache.shared.saveImageToDisk(image, for: url)
                    }
                    
                    return image
                } catch {
                    print("❌ Attempt \(attempt): Failed to load image \(url.absoluteString): \(error.localizedDescription)")
                    
                    if attempt < 3 {
                        // Wait before retrying (exponential backoff)
                        do {
                            let delaySeconds = pow(2.0, Double(attempt))
                            print("⏱️ Retrying in \(delaySeconds) seconds...")
                            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                        } catch {
                            // Ignore sleep errors (task cancellation)
                        }
                    } else {
                        print("❌ Failed after 3 attempts for: \(url.absoluteString)")
                        return nil
                    }
                }
            }
            
            return nil
        }
        
        // Store task
        await store.storeTask(task, for: url)
        
        // Wait for task to complete
        return try? await task.value
    }
    
    // Clear all cached images
    func clearCache() async {
        await store.clearMemoryCache()
        
        Task.detached {
            ImageDiskCache.shared.clearDiskCache()
        }
    }
} //
//  FirebaseImageLoader.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 04/05/2025.
//

import SwiftUI
import FirebaseStorage

class FirebaseImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var storage = Storage.storage()
    private var localCache = NSCache<NSString, UIImage>()
    
    // Load an image from Firebase Storage using the recommended Firebase approach
    func loadImage(from path: String, completion: @escaping (UIImage?) -> Void) {
        // Check if we have a cached version first
        let cacheKey = path as NSString
        if let cachedImage = localCache.object(forKey: cacheKey) {
            print("📂 Using cached image for: \(path)")
            completion(cachedImage)
            return
        }
        
        isLoading = true
        error = nil
        
        // Check if the path is a Storage URL or a Storage path
        let storageRef: StorageReference
        if path.hasPrefix("gs://") || path.hasPrefix("https://firebasestorage.googleapis.com") {
            print("🔥 Loading from full Firebase URL: \(path)")
            storageRef = storage.reference(forURL: path)
        } else {
            print("🔥 Loading from Firebase path: \(path)")
            storageRef = storage.reference().child(path)
        }
        
        // Download the image using Firebase SDK
        storageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Firebase download error: \(error.localizedDescription)")
                    self?.error = error
                    completion(nil)
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    print("❌ Failed to create image from data")
                    completion(nil)
                    return
                }
                
                print("✅ Successfully loaded image from Firebase")
                // Cache the image for future use
                self?.localCache.setObject(image, forKey: cacheKey)
                self?.image = image
                completion(image)
            }
        }
    }
    
    // Load an image using the download URL approach (alternative method)
    func loadImageViaURL(from path: String, completion: @escaping (UIImage?) -> Void) {
        // Check if we have a cached version first
        let cacheKey = path as NSString
        if let cachedImage = localCache.object(forKey: cacheKey) {
            print("📂 Using cached image for: \(path)")
            completion(cachedImage)
            return
        }
        
        isLoading = true
        error = nil
        
        let storageRef: StorageReference
        if path.hasPrefix("gs://") || path.hasPrefix("https://firebasestorage.googleapis.com") {
            storageRef = storage.reference(forURL: path)
        } else {
            storageRef = storage.reference().child(path)
        }
        
        // First get the download URL
        storageRef.downloadURL { [weak self] url, error in
            if let error = error {
                print("❌ Failed to get download URL: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.error = error
                    completion(nil)
                }
                return
            }
            
            guard let url = url else {
                print("❌ Received nil download URL")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(nil)
                }
                return
            }
            
            print("🔗 Got download URL: \(url.absoluteString)")
            
            // Now download the data using URLSession
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ URLSession download error: \(error.localizedDescription)")
                        self?.error = error
                        completion(nil)
                        return
                    }
                    
                    guard let data = data, let image = UIImage(data: data) else {
                        print("❌ Failed to create image from data")
                        completion(nil)
                        return
                    }
                    
                    print("✅ Successfully loaded image from URL")
                    // Cache the image for future use
                    self?.localCache.setObject(image, forKey: cacheKey)
                    self?.image = image
                    completion(image)
                }
            }.resume()
        }
    }
}

// A SwiftUI view that uses our Firebase image loader
struct FirebaseImage: View {
    let path: String?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var hasError = false
    
    // Initialize with a Firebase Storage path or URL
    init(path: String?) {
        self.path = path
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ZStack {
                    Color.gray.opacity(0.3)
                    ProgressView()
                }
            } else if !hasError {
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .onAppear(perform: loadImage)
            } else {
                // No image or placeholder shown if there was an error
                Color.clear
            }
        }
    }
    
    private func loadImage() {
        guard let imagePath = path, !isLoading else {
            hasError = true
            return
        }
        
        isLoading = true
        print("🔥 Loading Firebase image: \(imagePath)")
        
        let loader = FirebaseImageLoader()
        loader.loadImage(from: imagePath) { loadedImage in
            isLoading = false
            
            if let loadedImage = loadedImage {
                image = loadedImage
                hasError = false
            } else {
                hasError = true
                
                // Try alternative method if direct method fails
                loader.loadImageViaURL(from: imagePath) { altImage in
                    if let altImage = altImage {
                        image = altImage
                        hasError = false
                    } else {
                        hasError = true
                    }
                }
            }
        }
    }
} //
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
//  FormValidator.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/04/2025.
//

import Foundation

struct FormValidator {
    static func isFormValid(name: String, tags: [String], description: String, location: String) -> Bool {
        return !name.isEmpty && !tags.isEmpty && !description.isEmpty && !location.isEmpty
    }
}//
//  RemoteImageLoader.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 23/04/2025.
//

import SwiftUI
import FirebaseStorage

struct RemoteImage: View {
    let url: String?
    let aspectRatio: ContentMode
    let fallbackImage: String
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadError = false
    
    init(url: String?, aspectRatio: ContentMode = .fill, fallbackImage: String = "tacos") {
        self.url = url
        self.aspectRatio = aspectRatio
        self.fallbackImage = fallbackImage
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: aspectRatio)
            } else if isLoading {
                ProgressView()
            } else if loadError {
                Image(fallbackImage)
                    .resizable()
                    .aspectRatio(contentMode: aspectRatio)
            } else {
                Image(fallbackImage)
                    .resizable()
                    .aspectRatio(contentMode: aspectRatio)
            }
        }
        .onAppear {
            loadImageIfNeeded()
        }
    }
    
    private func loadImageIfNeeded() {
        guard let imageUrl = url, !isLoading, loadedImage == nil, !loadError else {
            return
        }
        
        isLoading = true
        print("🔄 Starting to load image: \(imageUrl)")
        
        // Use async Task to load the image
        Task {
            if imageUrl.contains("firebasestorage.googleapis.com") {
                print("🔥 Detected Firebase Storage URL")
                
                // First try direct URL approach - simplest and often works
                if let directUrl = URL(string: imageUrl) {
                    print("🌐 Trying direct URL loading first")
                    let directImage = await ImageCache.shared.image(for: directUrl)
                    
                    if let directImage = directImage {
                        print("✅ Direct URL loading successful!")
                        await MainActor.run {
                            loadedImage = directImage
                            isLoading = false
                        }
                        return
                    }
                }
                
                // If direct URL fails, try Firebase SDK approach
                await loadFirebaseImage(url: imageUrl)
            } else if let standardUrl = URL(string: imageUrl) {
                print("🌐 Detected standard URL")
                await loadCachedImage(url: standardUrl)
            } else {
                print("❌ Invalid URL format: \(imageUrl)")
                await MainActor.run {
                    isLoading = false
                    loadError = true
                }
            }
        }
    }
    
    private func loadCachedImage(url: URL) async {
        // No need for a do/catch here as ImageCache.shared.image() doesn't throw
        let cachedImage = await ImageCache.shared.image(for: url)
        
        await MainActor.run {
            if let cachedImage = cachedImage {
                loadedImage = cachedImage
                isLoading = false
                print("✅ Image loaded successfully from cache")
            } else {
                loadError = true
                isLoading = false
                print("❌ Failed to load image from cache")
            }
        }
    }
    
    private func loadFirebaseImage(url: String) async {
        print("🔥 Loading Firebase image: \(url)")
        
        // Check if we have the image URL cached from a previous Firebase download
        let key = "firebase_\(url.hash)"
        
        // Check if we have the actual download URL cached
        let defaults = UserDefaults.standard
        if let cachedDirectUrl = defaults.string(forKey: key),
           let directUrl = URL(string: cachedDirectUrl) {
            print("📦 Using cached Firebase direct URL: \(cachedDirectUrl)")
            await loadCachedImage(url: directUrl)
            return
        }
        
        // We need to get the download URL from Firebase
        do {
            print("⬇️ Getting download URL from Firebase...")
            let storage = Storage.storage()
            
            // Use a more reliable way to get the reference
            var storageRef: StorageReference
            
            // Handle both gs:// and https:// URLs
            if url.hasPrefix("gs://") {
                storageRef = storage.reference(forURL: url)
            } else {
                // Extract the path from https URL
                // Example: https://firebasestorage.googleapis.com/v0/b/[bucket]/o/[path]?token=...
                guard let pathStart = url.range(of: "/o/")?.upperBound,
                      let pathEnd = url.range(of: "?", options: [], range: pathStart..<url.endIndex)?.lowerBound else {
                    
                    print("⚠️ Trying direct reference as fallback")
                    storageRef = storage.reference(forURL: url)
                    
                    // Fallback to direct reference
                    await MainActor.run {
                        print("⚠️ Using direct URL reference")
                        if let directUrl = URL(string: url) {
                            Task {
                                await loadCachedImage(url: directUrl)
                            }
                            return
                        } else {
                            loadError = true
                            isLoading = false
                        }
                    }
                    return
                }
                
                let path = String(url[pathStart..<pathEnd])
                    .replacingOccurrences(of: "%2F", with: "/")
                print("📁 Extracted path: \(path)")
                
                storageRef = storage.reference().child(path)
            }
            
            // Get the download URL
            let downloadURL = try await storageRef.downloadURL()
            print("✅ Got Firebase download URL: \(downloadURL.absoluteString)")
            
            // Save the download URL for future use
            defaults.set(downloadURL.absoluteString, forKey: key)
            
            // Now load the image using our cache
            await loadCachedImage(url: downloadURL)
        } catch {
            await MainActor.run {
                print("❌ Firebase image error: \(error)")
                
                // Try direct URL as a fallback
                print("⚠️ Attempting fallback to direct URL...")
                if let directUrl = URL(string: url) {
                    Task {
                        await loadCachedImage(url: directUrl)
                    }
                } else {
                    loadError = true
                    isLoading = false
                }
            }
        }
    }
}

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
//
//  ListingStyling.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 18/03/2025.
//

import Foundation
import SwiftUI

struct ListingStyling {
    

    
    

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
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

    // MARK: - Amenity Symbols
    
    static func veganSymbol() -> some View {
        Image(systemName: "carrot.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }
    
    static func vegSymbol() -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }
    
    static func dogSymbol() -> some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }
    
    static func childSymbol() -> some View {
        Image(systemName: "figure.2.and.child.holdinghands")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

    // MARK: - Sunday Lunch Symbol
    
    static func sundayLunchSymbol() -> some View {
        Image(systemName: "oven.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

    


    // MARK: - Featured Symbol
    static func featuredSymbol() -> some View {
        Image(systemName: "medal.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
    }

    // MARK: - Tag Pills

    static func tagPill(_ tag: String) -> some View {
        return Text(tag.uppercased())
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Color(red: 0.93, green: 0.87, blue: 0.76)) // Light oak cream color
            )
    }

    // Helper function for backward compatibility
    static func styleForTag(_ tag: String) -> (systemName: String, color: Color) {
        // All tags now use the same style, but keeping method for backward compatibility
        return ("", Color(red: 0.93, green: 0.87, blue: 0.76)) // Light oak cream color
    }

    // View for displaying multiple tags horizontally
    static func tagsView(tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags, id: \.self) { tag in
                    tagPill(tag)
                }
            }
        }
    }

}
//
//  CachingImageView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 03/05/2025.
//

import SwiftUI

struct CachingImageView: View {
    let urlString: String?
    let aspectRatio: ContentMode
    let fallbackImageName: String
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError = false
    @State private var retryCount = 0
    
    init(urlString: String?, aspectRatio: ContentMode = .fill, fallbackImageName: String = "placeholder_food") {
        self.urlString = urlString
        self.aspectRatio = aspectRatio
        self.fallbackImageName = fallbackImageName
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: aspectRatio)
            } else if loadError {
                // Show fallback image from bundle
                Image(fallbackImageName)
                    .resizable()
                    .aspectRatio(contentMode: aspectRatio)
                    .overlay(
                        Button(action: {
                            // Reset error state and retry loading
                            loadError = false
                            retryCount = 0
                            loadImage()
                        }) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle()),
                        alignment: .bottomTrailing
                    )
            } else {
                Color.gray.opacity(0.3)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let urlString = urlString, 
              let url = URL(string: urlString),
              !isLoading, !loadError || retryCount < 3 else {
            if loadError {
                print("⚠️ Not retrying after 3 failed attempts")
            }
            return
        }
        
        isLoading = true
        retryCount += 1
        print("🔍 CachingImageView loading: \(urlString) (attempt \(retryCount))")
        
        Task {
            do {
                if let loadedImage = await ImageCache.shared.image(for: url) {
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                        self.loadError = false
                        print("✅ Image loaded successfully")
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                        self.loadError = true
                        print("❌ Failed to load image - using fallback")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadError = true
                    print("❌ Error loading image: \(error.localizedDescription)")
                }
            }
        }
    }
} //
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
//
//  CachedAsyncImage.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 03/05/2025.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var cachedImage: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let cachedImage {
                content(Image(uiImage: cachedImage).resizable())
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard !isLoading, let url = url else { return }
        
        isLoading = true
        
        Task {
            let image = await ImageCache.shared.image(for: url)
            
            await MainActor.run {
                self.cachedImage = image
                self.isLoading = false
            }
        }
    }
}

// Convenience initializer with animation
extension CachedAsyncImage {
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(url: url, scale: scale, content: content, placeholder: placeholder)
    }
}

// Convenience initializer with simple placeholder
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            scale: scale,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}

// Convenience initializer with default content and placeholder
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, scale: CGFloat = 1) {
        self.init(
            url: url,
            scale: scale,
            content: { $0 },
            placeholder: { ProgressView() }
        )
    }
} //
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
} //
//  FirebaseStorageImage.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 04/05/2025.
//

import SwiftUI
import FirebaseStorage

// Shared cache for images
private class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct FirebaseStorageImage: View {
    let urlString: String?
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                // Nothing shown if no image or error
                Color.clear
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let urlString = urlString else {
            print("⚠️ No URL provided for FirebaseStorageImage")
            isLoading = false
            return
        }
        
        // Check if image is already cached
        if let cachedImage = ImageCache.shared.getImage(for: urlString) {
            print("📂 Using cached image for: \(urlString)")
            image = cachedImage
            isLoading = false
            return
        }
        
        print("🔄 Attempting to load: \(urlString)")
        
        // First try direct URL loading if it's an https URL
        if urlString.hasPrefix("https://") {
            if let url = URL(string: urlString) {
                print("🌐 Loading via URLSession: \(urlString)")
                URLSession.shared.dataTask(with: url) { data, response, error in
                    DispatchQueue.main.async {
                        if let data = data, let downloadedImage = UIImage(data: data) {
                            print("✅ Direct URL loading successful")
                            self.image = downloadedImage
                            self.isLoading = false
                            // Cache the successfully loaded image
                            ImageCache.shared.setImage(downloadedImage, for: urlString)
                            return
                        } else {
                            // Continue to Firebase loading method
                            print("⚠️ Direct URL loading failed, trying Firebase...")
                            loadFromFirebase(urlString: urlString)
                        }
                    }
                }.resume()
                return
            }
        }
        
        // If not an https URL or URL creation failed, try Firebase
        loadFromFirebase(urlString: urlString)
    }
    
    private func loadFromFirebase(urlString: String) {
        let storage = Storage.storage()
        
        // Create appropriate reference
        let storageRef: StorageReference
        if urlString.hasPrefix("gs://") {
            print("🔥 Using gs:// reference: \(urlString)")
            storageRef = storage.reference(forURL: urlString)
        } else if urlString.hasPrefix("https://firebasestorage.googleapis.com") {
            print("🔥 Using https:// Firebase reference: \(urlString)")
            storageRef = storage.reference(forURL: urlString)
        } else {
            print("🔥 Using path in default bucket: \(urlString)")
            storageRef = storage.reference().child(urlString)
        }
        
        // Get the data directly
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Firebase Storage error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data, let downloadedImage = UIImage(data: data) else {
                    print("❌ Invalid image data from Firebase")
                    return
                }
                
                print("✅ Successfully loaded image from Firebase")
                self.image = downloadedImage
                
                // Cache the successfully loaded image
                ImageCache.shared.setImage(downloadedImage, for: urlString)
            }
        }
    }
} //
//  ListingCardView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    @State private var showingDetailView = false
    
    var body: some View {
        Button(action: {
            showingDetailView = true
            // Print image URL for debugging
            if let imageUrl = listing.imageUrl {
                print("📱 Listing Card for \(listing.name) has imageUrl: \(imageUrl)")
            }
        }) {
            // Card structure without symbol margin
            ZStack(alignment: .top) {
                // Main content area excluding category (starts below the category)
                VStack(alignment: .leading, spacing: 4) {
                    // Listing name
                    Text(listing.name)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    // Description (if available)
                    if !listing.description.isEmpty {
                        Text(listing.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3) // Allow up to 3 lines
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                            .frame(width: UIScreen.main.bounds.width * 0.45, alignment: .leading)
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                    
                    // Footer with just location
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption2)
                        
                        Text(listing.location.uppercased())
                            .font(.caption2)
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 40) // Space for the tags row above
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Tags and cuisine row - positioned at the very top
                HStack {
                    // Only show tags if available
                    if !listing.tags.isEmpty {
                        ListingStyling.tagsView(tags: listing.tags)
                    }
                    
                    // Only show cuisine if it's not empty
                    if !listing.cuisine.isEmpty {
                        Text(listing.cuisine)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1)
                
                // Floating image box - vertically centered
                FirebaseStorageImage(urlString: listing.imageUrl)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.trailing, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .zIndex(2)
                    .onAppear {
                        if let imageUrl = listing.imageUrl {
                            print("👁️ Card image URL for \(listing.name): \(imageUrl)")
                        } else {
                            print("⚠️ No image URL for \(listing.name)")
                        }
                    }
            }
            .frame(height: 160)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
    var onFilterTap: () -> Void
    var onAboutTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main header content
            HStack {
                Text("Brizlist")
                    .font(.headline)
                    .fontWeight(.bold)

                if viewModel.hasActiveFilters || viewModel.hasTagFilters {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        let count = viewModel.activeFilterValues.values.filter { $0 }.count 
                                  + (viewModel.selectedTags.isEmpty ? 0 : 1)
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                // Filter button
                Button(action: {
                    onFilterTap()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.headline)
                        .foregroundColor(.black)
                }

                // More info about brizlist
                Button(action: {
                    onAboutTap()
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
    }
}

#Preview {
    HeaderView(
        viewModel: ListingsViewModel(),
        onFilterTap: {},
        onAboutTap: {}
    )
}
//
//  PlaceholderImageView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 04/05/2025.
//

import SwiftUI

struct PlaceholderImageView: View {
    let aspectRatio: ContentMode
    
    init(aspectRatio: ContentMode = .fill) {
        self.aspectRatio = aspectRatio
    }
    
    var body: some View {
        ZStack {
            // Base color
            Color.gray.opacity(0.2)
            
            // Food icon
            VStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.7))
                
                Text("Image")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .aspectRatio(contentMode: aspectRatio)
    }
}

struct PlaceholderImageView_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderImageView()
            .frame(width: 200, height: 200)
    }
} //
//  ContentView.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ListingsViewModel()
    @State private var showingFilterSheet = false
    @State private var showingAboutSheet = false
    
    var body: some View {
        ZStack {
            // System grey color to match the header
            Color(.systemGray6)  // This is the same color used in HeaderView
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    viewModel: viewModel,
                    onFilterTap: { showingFilterSheet = true },
                    onAboutTap: { showingAboutSheet = true }
                )
                
                // Main scrolling content
                ListingsScrollView(
                    viewModel: viewModel,
                    onFilterTap: { showingFilterSheet = true }
                )
            }
        }
        .onAppear {
            viewModel.fetchListings()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") {
                viewModel.showError = false
            }
        } message: { errorMessage in
            Text(errorMessage)
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

// Extracted ScrollView into a separate view
struct ListingsScrollView: View {
    @ObservedObject var viewModel: ListingsViewModel
    var onFilterTap: () -> Void
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("refresh")) {
                viewModel.fetchListings()
            }
            
            LazyVStack(spacing: 16) {
                // Featured listings section
                if !viewModel.featuredListings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Featured section header with enhanced styling
                        HStack {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                            
                            Text("FEATURED")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        
                        // Featured listings
                        ForEach(viewModel.featuredListings) { listing in
                            ListingCardView(
                                listing: listing
                            )
                            .padding(.horizontal)
                            .onAppear {
                                if listing.id == viewModel.featuredListings.last?.id {
                                    viewModel.loadMoreListings()
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.08)) // Very light blue background
                            .padding(.horizontal, 8)
                    )
                    
                    // Add a bit more space after the featured section
                    Spacer()
                        .frame(height: 12)
                }
                
                // Regular listings
                ForEach(viewModel.listings) { listing in
                    ListingCardView(
                        listing: listing
                    )
                    .padding(.horizontal)
                    .onAppear {
                        if listing.id == viewModel.listings.last?.id {
                            viewModel.loadMoreListings()
                        }
                    }
                }
                
                // No results message when filtering results in no matches
                if viewModel.noResultsFromFiltering {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                        
                        Text("No listings match all your filters")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Try selecting fewer filters or a different combination")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        if !viewModel.selectedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected tags:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                                        Text(tag.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.7))
                                            )
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        Button("Adjust Filters") {
                            // This will open the filter sheet
                            onFilterTap()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                // Loading indicator and end of list message
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
    // Add a state for selected tags
    @State private var localSelectedTags: Set<String> = []
    // Add state to track if current selection would yield results
    @State private var wouldYieldResults: Bool = true
    @State private var isCheckingResults: Bool = false
    
    // Initialize with current filters
    init(viewModel: ListingsViewModel) {
        self.viewModel = viewModel
        
        // Make a copy of the current filter values
        var initialFilters: [String: Bool] = [:]
        for filter in viewModel.availableFilters {
            initialFilters[filter.field] = viewModel.activeFilterValues[filter.field] ?? false
        }
        self._localFilters = State(initialValue: initialFilters)
        self._localSelectedTags = State(initialValue: viewModel.selectedTags)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Tag filter section
                Section(header: Text("Filter by Tags")) {
                    // Use a static list of all possible tags instead of getting from current results
                    let allPossibleTags = ["bakery", "cafe", "store", "wine bar", "pizzeria", "pub", "restaurant", "coffee shop"]
                    
                    // Calculate left and right columns
                    let leftColumnTags = stride(from: 0, to: allPossibleTags.count, by: 2).map { allPossibleTags[min($0, allPossibleTags.count - 1)] }
                    let rightColumnTags = stride(from: 1, to: allPossibleTags.count, by: 2).map { allPossibleTags[min($0, allPossibleTags.count - 1)] }
                    let maxCount = max(leftColumnTags.count, rightColumnTags.count)
                    
                    // Create the grid container
                    HStack(alignment: .top, spacing: 0) {
                        // Left column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < leftColumnTags.count {
                                    tagToggleRow(tag: leftColumnTags[index], 
                                               isSelected: localSelectedTags.contains(leftColumnTags[index])) { isOn in
                                        if isOn {
                                            localSelectedTags.insert(leftColumnTags[index])
                                        } else {
                                            localSelectedTags.remove(leftColumnTags[index])
                                        }
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Center divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)
                            .padding(.vertical, 4)
                        
                        // Right column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < rightColumnTags.count {
                                    tagToggleRow(tag: rightColumnTags[index], 
                                               isSelected: localSelectedTags.contains(rightColumnTags[index])) { isOn in
                                        if isOn {
                                            localSelectedTags.insert(rightColumnTags[index])
                                        } else {
                                            localSelectedTags.remove(rightColumnTags[index])
                                        }
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16) // Add more space at the start of the right column
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Filter By Amenities")) {
                    // Create two columns for amenity filters
                    let filters = viewModel.availableFilters
                    let leftFilters = stride(from: 0, to: filters.count, by: 2).map { filters[min($0, filters.count - 1)] }
                    let rightFilters = stride(from: 1, to: filters.count, by: 2).map { filters[min($0, filters.count - 1)] }
                    let maxCount = max(leftFilters.count, rightFilters.count)
                    
                    // Create the grid container
                    HStack(alignment: .top, spacing: 0) {
                        // Left column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < leftFilters.count {
                                    amenityToggleRow(filter: leftFilters[index], 
                                                   isSelected: localFilters[leftFilters[index].field] ?? false) { isOn in
                                        localFilters[leftFilters[index].field] = isOn
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Center divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)
                            .padding(.vertical, 4)
                        
                        // Right column
                        VStack(spacing: 12) {
                            ForEach(0..<maxCount, id: \.self) { index in
                                if index < rightFilters.count {
                                    amenityToggleRow(filter: rightFilters[index], 
                                                   isSelected: localFilters[rightFilters[index].field] ?? false) { isOn in
                                        localFilters[rightFilters[index].field] = isOn
                                    }
                                } else {
                                    // Empty cell for alignment
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16) // Add more space at the start of the right column
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    // Explain the filtering logic to users
                    if localSelectedTags.count > 1 || localFilters.values.contains(true) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .padding(.top, 2)
                            
                            Text("Selected filters work as 'AND' conditions - listings must match ALL selected criteria")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Show warning if the filter combination wouldn't yield results
                    if !wouldYieldResults {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No listings match all selected criteria")
                                    .foregroundColor(.orange)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                
                                Text("Try selecting fewer filters or a different combination")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Apply button applies all filters at once
                    Button("Apply Filters") {
                        // Update the view model with our local changes
                        for filter in viewModel.availableFilters {
                            viewModel.activeFilterValues[filter.field] = localFilters[filter.field] ?? false
                        }
                        
                        // Update selected tags
                        viewModel.selectedTags = localSelectedTags
                        
                        viewModel.fetchListings()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(isCheckingResults || (!wouldYieldResults && (localSelectedTags.count > 0 || localFilters.values.contains(true))))
                    .opacity(wouldYieldResults ? 1.0 : 0.5)
                    
                    // Clear all button
                    Button("Clear All Filters and Apply") {
                        // Clear all local filters
                        for filter in viewModel.availableFilters {
                            localFilters[filter.field] = false
                        }
                        localSelectedTags.removeAll()
                        
                        // Apply changes to view model
                        for filter in viewModel.availableFilters {
                            viewModel.activeFilterValues[filter.field] = false
                        }
                        viewModel.selectedTags.removeAll()
                        
                        // Refresh and dismiss
                        viewModel.fetchListings()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: localFilters) { checkFilterResults() }
            .onChange(of: localSelectedTags) { checkFilterResults() }
            .onAppear { checkFilterResults() }
        }
    }
    
    // Add this function to check if filters would yield results
    private func checkFilterResults() {
        // Only check if there are actual filters applied
        let hasFilters = localSelectedTags.count > 0 || localFilters.values.contains(true)
        
        if hasFilters {
            isCheckingResults = true
            // Use a background thread to not block the UI
            DispatchQueue.global(qos: .userInitiated).async {
                let hasResults = viewModel.wouldFiltersYieldResults(tags: localSelectedTags, amenities: localFilters)
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.wouldYieldResults = hasResults
                    self.isCheckingResults = false
                }
            }
        } else {
            // If no filters, we'll definitely have results
            wouldYieldResults = true
            isCheckingResults = false
        }
    }
    
    // Helper to create a consistent tag toggle row
    private func tagToggleRow(tag: String, isSelected: Bool, onToggle: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(tag.capitalized)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 2) // Reduce minimum spacing to bring toggle closer to text
            
            // Compact toggle
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .toggleStyle(CompactToggleStyle())
            .frame(width: 36) // Slightly smaller width
        }
        .padding(.trailing, 16) // Add right padding to move toggles away from divider
    }
    
    // Helper to create a consistent amenity toggle row
    private func amenityToggleRow(filter: ListingsViewModel.FilterOption, isSelected: Bool, onToggle: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(filter.displayName)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 2) // Reduce minimum spacing to bring toggle closer to text
            
            // Compact toggle
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .toggleStyle(CompactToggleStyle())
            .frame(width: 36) // Slightly smaller width
        }
        .padding(.trailing, 16) // Add right padding to move toggles away from divider
    }
}

// Custom compact toggle style
struct CompactToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.blue : Color(.systemGray5))
                .frame(width: 36, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 8 : -8)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
