//
//  CardStatusBadge.swift
//  brizlist_test1
//
//  Created by Stephen Dawes on 27/05/2025.
//

import SwiftUI

/// A status badge component that appears in the top-left corner of cards
/// - Custom corner radius pattern for a "ticket stub" effect
/// - Displays card status text (FEATURED, NEW, COMING SOON)
/// - Reusable across different card types
struct CardStatusBadge: View {
    let statusText: String
    let badgeType: BadgeType
    let cardWidth: CGFloat
    
    // Badge type enumeration with associated colors
    enum BadgeType {
        case featured
        case new
        case comingSoon
        
        var backgroundColor: Color {
            switch self {
            case .featured:
                return Color.blue
            case .new:
                return Color.green
            case .comingSoon:
                return Color.orange
            }
        }
        
        var borderColor: Color {
            return backgroundColor // Same color for border and badge
        }
    }
    
    // Badge dimensions
    private var badgeWidth: CGFloat {
        cardWidth / 4 // One-fourth of card width (increased from 1/6)
    }
    
    private let badgeHeight: CGFloat = 28
    private let cardCornerRadius: CGFloat = 12
    
    var body: some View {
        Text(statusText.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(width: badgeWidth, height: badgeHeight)
            .background(badgeType.backgroundColor)
            .clipShape(
                CustomCornerShape(
                    topLeft: cardCornerRadius,
                    topRight: 0,
                    bottomLeft: 0,
                    bottomRight: cardCornerRadius
                )
            )
    }
}

/// Custom shape with individual corner radius control
struct CustomCornerShape: Shape {
    let topLeft: CGFloat
    let topRight: CGFloat
    let bottomLeft: CGFloat
    let bottomRight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // Start from top-left corner (accounting for radius)
        path.move(to: CGPoint(x: 0, y: topLeft))
        
        // Top-left corner
        if topLeft > 0 {
            path.addArc(
                center: CGPoint(x: topLeft, y: topLeft),
                radius: topLeft,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
        }
        
        // Top edge to top-right
        path.addLine(to: CGPoint(x: width - topRight, y: 0))
        
        // Top-right corner
        if topRight > 0 {
            path.addArc(
                center: CGPoint(x: width - topRight, y: topRight),
                radius: topRight,
                startAngle: Angle(degrees: 270),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
        }
        
        // Right edge to bottom-right
        path.addLine(to: CGPoint(x: width, y: height - bottomRight))
        
        // Bottom-right corner
        if bottomRight > 0 {
            path.addArc(
                center: CGPoint(x: width - bottomRight, y: height - bottomRight),
                radius: bottomRight,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
        }
        
        // Bottom edge to bottom-left
        path.addLine(to: CGPoint(x: bottomLeft, y: height))
        
        // Bottom-left corner
        if bottomLeft > 0 {
            path.addArc(
                center: CGPoint(x: bottomLeft, y: height - bottomLeft),
                radius: bottomLeft,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
        }
        
        // Left edge back to start
        path.addLine(to: CGPoint(x: 0, y: topLeft))
        
        return path
    }
}

// MARK: - Preview
struct CardStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Featured badge
            CardStatusBadge(
                statusText: "FEATURED",
                badgeType: .featured,
                cardWidth: 300
            )
            
            // New badge
            CardStatusBadge(
                statusText: "NEW",
                badgeType: .new,
                cardWidth: 300
            )
            
            // Coming Soon badge
            CardStatusBadge(
                statusText: "COMING SOON",
                badgeType: .comingSoon,
                cardWidth: 300
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

