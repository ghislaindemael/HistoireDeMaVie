//
//  IconView.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import SwiftUI

struct IconView: View {
    let iconString: String
    var size: CGFloat = 25
    var tint: Color = .primary
    
    private enum IconType {
        case sfSymbol
        case asset
        case emoji
        case svg
        case unknown
    }
    
    private var detectedType: IconType {
        if iconString.isEmpty {
            return .unknown
        } else if UIImage(systemName: iconString) != nil {
            return .sfSymbol
        } else if UIImage(named: iconString) != nil {
            return .asset
        } else if iconString.unicodeScalars.count == 1,
                  iconString.unicodeScalars.first?.properties.isEmoji == true {
            return .emoji
        } else if iconString.hasSuffix(".svg") {
            return .svg
        }
        return .unknown
    }
    
    var body: some View {
        switch detectedType {
            case .sfSymbol:
                Image(systemName: iconString)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(tint)
                
            case .asset:
                Image(iconString) // xcassets
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(tint)
                
            case .emoji:
                Text(iconString)
                    .font(.system(size: size))
                
            case .svg:
                Image(iconString)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                
            case .unknown:
                Image(systemName: "questionmark.circle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(.gray)
        }
    }
}
