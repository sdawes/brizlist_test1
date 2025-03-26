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
