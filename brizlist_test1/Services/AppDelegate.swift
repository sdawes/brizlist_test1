//
//  AppDelegate.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 13/03/2025.
//

import UIKit
import SwiftUI
import FirebaseCore
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