//
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
    @State private var threshold: CGFloat = 50
    @State private var opacity: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: coordinateSpace).minY
            let progress = min(max(0, offset / threshold), 1.0)
            
            ZStack(alignment: .center) {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .opacity(opacity)
                        .animation(.easeIn(duration: 0.2), value: opacity)
                }
            }
            .frame(width: geometry.size.width)
            .offset(y: max(0, offset / 2))
            .onChange(of: offset) { newOffset in
                if newOffset > threshold && !isRefreshing {
                    // Only trigger refresh when pulling past threshold
                    withAnimation(.easeInOut(duration: 0.2)) {
                        opacity = 1.0
                        isRefreshing = true
                    }
                    
                    // Apply the refresh action
                    onRefresh()
                    
                    // Automatically reset after a reasonable delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            opacity = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isRefreshing = false
                        }
                    }
                } else if newOffset > 0 && !isRefreshing {
                    // Show the spinner with opacity matching pull progress
                    opacity = Double(progress)
                }
            }
        }
        .padding(.top, -50)
        .frame(height: 0)
    }
}
