//
//  PercentageBarView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//
import SwiftUI

struct PercentageBarView: View {
    let percentage: Double  // 0...100
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background bar (gray for empty part)
                Rectangle()
                    .frame(height: 10)
                    .foregroundColor(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                
                // Filled bar with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.black, .red, .orange, .yellow, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(percentage / 100), height: 10)
                    .cornerRadius(5)
            }
        }
        .frame(height: 10)
    }
}
