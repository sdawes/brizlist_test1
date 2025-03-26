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
