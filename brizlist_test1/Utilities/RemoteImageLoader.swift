//
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
        
        if imageUrl.contains("firebasestorage.googleapis.com") {
            loadFirebaseImage(url: imageUrl)
        } else {
            loadStandardImage(url: imageUrl)
        }
    }
    
    private func loadFirebaseImage(url: String) {
        print("🔥 Loading image using Firebase SDK: \(url)")
        
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: url)
        
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ Firebase image load error: \(error.localizedDescription)")
                    loadError = true
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    print("✅ Firebase image loaded successfully: \(data.count) bytes")
                    loadedImage = image
                } else {
                    print("❌ Firebase returned data but couldn't create image")
                    loadError = true
                }
            }
        }
    }
    
    private func loadStandardImage(url: String) {
        print("🌐 Loading image using URLSession: \(url)")
        
        guard let imageURL = URL(string: url) else {
            print("❌ Invalid URL format")
            isLoading = false
            loadError = true
            return
        }
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ URLSession error: \(error.localizedDescription)")
                    loadError = true
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    print("✅ Standard image loaded successfully")
                    loadedImage = image
                } else {
                    print("❌ Standard image loading failed")
                    loadError = true
                }
            }
        }.resume()
    }
}

