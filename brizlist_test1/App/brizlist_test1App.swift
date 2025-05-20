//
//  brizlist_test1App.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import UIKit

// Add a class that conforms to UIApplicationDelegate to handle orientation restrictions
class AppDelegate: NSObject, UIApplicationDelegate {
    // Restrict app to portrait orientation only
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait // This restricts the app to portrait orientation only
    }
}

@main
struct BrizlistApp: App {
    // Register the app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
                .preferredColorScheme(.light) // Force light mode throughout the app
        }
    }
}
