//
//  Colors+HDMV.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.09.2025.
//


import SwiftUI

extension Color {
    static var secondaryBackgroundColor: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.tertiarySystemBackground
            } else {
                return UIColor.secondarySystemBackground
            }
        })
    }
    
    static var tertiaryBackgroundColor: Color {
        Color(uiColor: .tertiarySystemGroupedBackground)        
        // Use systemGray5 or systemGray6 for a more pronounced difference
        // Color(uiColor: .systemGray6) // Lighter gray
        // Color(uiColor: .systemGray5) // Darker gray than 6
    }
}
