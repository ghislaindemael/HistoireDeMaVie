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
}
