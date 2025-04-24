# Brizlist

A guide to exploring the best of Bristol's food and drink scene.

## Features

- Browse local listings sorted by featured status
- Filter by tags and amenities 
- View detailed information about each listing
- Persistent image caching for better performance
- Firebase integration for real-time updates

## Image Caching

The app implements a robust image caching system to minimize network requests and improve performance:

- In-memory caching for fast access during a session
- Persistent disk-based caching for images across app launches
- Automatic cache cleanup of old images (older than 7 days)
- Deduplication of concurrent image requests
- Special handling for Firebase Storage URLs

This ensures that images only need to be downloaded once and are then stored locally, significantly reducing data usage and improving scrolling performance.

## Filtering

Listings can be filtered using an "AND" approach:

- When multiple tags are selected, only listings that have ALL the selected tags will be shown
- When multiple amenities are selected, a listing must have ALL the selected amenities
- Users receive feedback when no listings match their filter criteria

## Development

Built with:
- SwiftUI
- Firebase (Firestore and Storage)
- Swift Concurrency (async/await) 