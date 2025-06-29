//
//  GradientPercentageBarView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//


import SwiftUI

struct GradientPercentageBarView: View {
    let percentage: Double // 0...100
    
    private let gradientColors = Gradient(colors: [
        .black,
        .red,
        .orange,
        .yellow,
        .green
    ])
    
    private var colorForPercentage: Color {
        let normalized = min(max(percentage / 100, 0), 1)
    
        let stops = gradientColors.stops
        let segmentCount = stops.count - 1
        
        let segment = min(Int(normalized * Double(segmentCount)), segmentCount - 1)
        let segmentStart = Double(segment) / Double(segmentCount)
        let segmentEnd = Double(segment + 1) / Double(segmentCount)
        
        let localProgress = (normalized - segmentStart) / (segmentEnd - segmentStart)
        
        let startColor = UIColor(stops[segment].color)
        let endColor = UIColor(stops[segment + 1].color)
        
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0,0,0,0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0,0,0,0)
        
        startColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * CGFloat(localProgress)
        let g = g1 + (g2 - g1) * CGFloat(localProgress)
        let b = b1 + (b2 - b1) * CGFloat(localProgress)
        let a = a1 + (a2 - a1) * CGFloat(localProgress)
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
    
    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(colorForPercentage)
                .frame(width: geo.size.width * CGFloat(percentage / 100), height: 8)
                .animation(.easeInOut, value: percentage)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.systemGray5))
                )
        }
        .frame(height: 8)
    }
}
