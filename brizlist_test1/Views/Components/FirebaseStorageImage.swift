//
//  FirebaseStorageImage.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 04/05/2025.
//

import SwiftUI
import FirebaseStorage

// Enhanced cache with disk persistence
private class ImageCache {
    static let shared = ImageCache()
    private var memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheDirectory: URL
    
    init() {
        // Create a persistent cache directory in the app's cache folder
        let cacheDirectories = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        diskCacheDirectory = cacheDirectories[0].appendingPathComponent("BrizlistImageCache", isDirectory: true)
        
        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: diskCacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: diskCacheDirectory, 
                                               withIntermediateDirectories: true,
                                               attributes: nil)
            } catch {
                print("❌ Error creating disk cache directory: \(error)")
            }
        }
    }
    
    // Check if image exists in memory cache
    func getFromMemory(for key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }
    
    // Save image to memory cache
    func saveToMemory(_ image: UIImage, for key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
    }
    
    // Get file URL for a key
    private func fileURL(for key: String) -> URL {
        // Use a hash of the key for the filename to ensure valid filenames
        let filename = "\(key.hash).jpg"
        return diskCacheDirectory.appendingPathComponent(filename)
    }
    
    // Save image to disk
    func saveToDisk(_ image: UIImage, for key: String) {
        let url = fileURL(for: key)
        
        // Convert image to JPEG data
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: url)
            } catch {
                print("❌ Failed to write image to disk: \(error)")
            }
        }
    }
    
    // Get image from disk
    func getFromDisk(for key: String) -> UIImage? {
        let url = fileURL(for: key)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            if let image = UIImage(data: data) {
                return image
            }
        } catch {
            print("❌ Failed to read image from disk: \(error)")
        }
        
        return nil
    }
    
    // Get image from cache (memory or disk)
    func getImage(for key: String) -> UIImage? {
        // First check memory cache (fastest)
        if let memoryImage = getFromMemory(for: key) {
            return memoryImage
        }
        
        // Then check disk cache
        if let diskImage = getFromDisk(for: key) {
            // Store in memory for faster access next time
            saveToMemory(diskImage, for: key)
            return diskImage
        }
        
        return nil
    }
    
    // Save image to both memory and disk caches
    func setImage(_ image: UIImage, for key: String) {
        saveToMemory(image, for: key)
        
        // Save to disk on background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.saveToDisk(image, for: key)
        }
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
            isLoading = false
            return
        }
        
        // Check if image is already cached (in memory or on disk)
        if let cachedImage = ImageCache.shared.getImage(for: urlString) {
            image = cachedImage
            isLoading = false
            return
        }
        
        // First try direct URL loading if it's an https URL
        if urlString.hasPrefix("https://") {
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    DispatchQueue.main.async {
                        if let data = data, let downloadedImage = UIImage(data: data) {
                            self.image = downloadedImage
                            self.isLoading = false
                            // Cache the successfully loaded image
                            ImageCache.shared.setImage(downloadedImage, for: urlString)
                            return
                        } else {
                            // Continue to Firebase loading method
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
            storageRef = storage.reference(forURL: urlString)
        } else if urlString.hasPrefix("https://firebasestorage.googleapis.com") {
            storageRef = storage.reference(forURL: urlString)
        } else {
            // Add .jpeg extension if missing for simple paths
            let pathWithExtension = urlString.contains(".") ? urlString : "\(urlString).jpeg"
            storageRef = storage.reference().child(pathWithExtension)
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
                
                self.image = downloadedImage
                
                // Cache the successfully loaded image (both memory and disk)
                ImageCache.shared.setImage(downloadedImage, for: urlString)
            }
        }
    }
} 