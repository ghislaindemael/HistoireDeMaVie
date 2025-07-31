//
//  IconView.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import SwiftUI

struct IconView: View {
    let iconString: String
    
    private enum IconType {
        case sfSymbol
        case emoji
        case svg
    }
    
    private var detectedType: IconType {
        // 1. SF Symbol Check: Try to initialize a UIImage with the string as a system name.
        // If it succeeds, it's a valid SF Symbol.
        if UIImage(systemName: iconString) != nil {
            return .sfSymbol
        }
        
        if iconString.count == 1, let firstScalar = iconString.unicodeScalars.first, firstScalar.properties.isEmoji {
            return .emoji
        }
        
        return .svg
    }
    
    var body: some View {
        switch detectedType {
        case .sfSymbol:
            Image(systemName: iconString)
                .frame(width: 20, alignment: .center)
        case .emoji:
            Text(iconString)
        case .svg:
            Image(iconString)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20, alignment: .center)
        }
    }
}
