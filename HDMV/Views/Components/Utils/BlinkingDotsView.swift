//
//  BlinkingDotsView.swift
//  HDMV
//
//  Created by Ghislain Demael on 02.08.2025.
//

import SwiftUI

struct BlinkingDotsView: View {
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 2) {
            Circle().frame(width: 5, height: 5)
            Circle().frame(width: 5, height: 5)
            Circle().frame(width: 5, height: 5)
        }
        .foregroundColor(.secondary)
        .opacity(isVisible ? 1 : 0.2) // Fade in/out
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isVisible)
        .onAppear {
            isVisible.toggle()
        }
    }
}
