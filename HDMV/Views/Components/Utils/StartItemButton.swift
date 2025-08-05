//
//  StartItemButton.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.08.2025.
//

import SwiftUI

/// A reusable button with a specific style and a "disappear on tap" animation.
struct StartItemButton: View {
    let title: String
    let action: () -> Void
    
    @State private var isDisappearing = false
    
    var body: some View {
        Button(title) {
            withAnimation(.easeInOut(duration: 1)) {
                isDisappearing = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                action()
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .buttonStyle(.plain)
        .scaleEffect(x: 1.0, y: isDisappearing ? 0.01 : 1.0, anchor: .center)
        .opacity(isDisappearing ? 0 : 1)
    }
}
