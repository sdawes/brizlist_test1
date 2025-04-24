//
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
} 