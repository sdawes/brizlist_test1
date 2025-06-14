# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Brizlist is an iOS SwiftUI app for exploring Bristol's food and drink scene. Users can browse local listings, filter by tags and amenities, and view detailed information about each venue.

## Development Environment

### Building and Running
- Open `brizlist_test1.xcodeproj` in Xcode
- Build target: `brizlist_test1`
- The app is restricted to portrait orientation only
- No tests are currently configured

### Key Technologies
- SwiftUI for UI
- Firebase Firestore for data storage
- Firebase Storage for images
- Swift Concurrency (async/await)

## Architecture

### Data Models
- `Listing`: Core data model with multiple tag categories (tags1, tags2, tags3), card styling, and Firebase integration
- `CuratedList`: Collections of listings with display order and metadata

### Key Components
- `ListingsViewModel`: Central state management for listings data, filtering, and Firebase operations
- `FirebaseStorageImage`: Custom image loading component with dual-layer caching (memory + disk persistence)
- Card system with different styling types: `default`, `large`, `new`, `coming`

### Firebase Configuration
- Firestore offline persistence enabled with 100MB cache
- Firebase logs reduced to errors only for cleaner Xcode output
- Image caching system stores images locally (7-day cleanup cycle)

### Filtering System
- AND-based filtering: listings must match ALL selected criteria
- Three-tier tag system (tags1/tags2/tags3) with different purposes
- Location-based filtering
- Card styling filters
- Firestore query optimization with client-side post-filtering

### Image Caching
The app implements a sophisticated caching system:
- In-memory cache for active session performance
- Persistent disk cache across app launches
- Automatic cleanup of images older than 7 days
- Deduplication of concurrent requests
- Special handling for Firebase Storage URLs

### View Structure
- `ContentView`: Main container with header and scrollable listings
- Cards: Different visual styles based on `cardStyling` field
- Components: Reusable UI elements like `FirebaseStorageImage`, `HeaderView`
- Pages: Main views and filter sheets

## Development Notes

### Firebase Integration
- App initializes Firebase on startup with offline persistence
- Uses `@DocumentID` for automatic Firestore document ID handling
- Firestore queries are optimized with pagination (20 items per page)
- Real-time updates supported through Firestore listeners

### Performance Considerations
- Image loading is optimized with aggressive caching
- List scrolling performance enhanced through image deduplication
- Firestore queries use indexing and pagination
- Client-side filtering applied after Firestore query optimization

### State Management
- `@StateObject` and `@ObservableObject` for reactive UI updates
- Complex filtering state managed in `ListingsViewModel`
- Error handling with user-friendly alerts