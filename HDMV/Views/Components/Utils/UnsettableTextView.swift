//
//  UnsettableTextView.swift
//  HDMV
//
//  Created by Ghislain Demael on 18.06.2026.
//

import SwiftUI

struct UnsettableView<Content: View>: View {
    let isUnset: Bool
    var font: Font = .title3.bold()
    var isItalicized: Bool = false
    var fallbackText: String = "Unset"
    var fallbackIconString: String? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Group {
            if isUnset {
                HStack(spacing: 6) {
                    if let icon = fallbackIconString {
                        IconView(iconString: icon, size: 16)
                    }
                    Text(fallbackText)
                }
                    .foregroundColor(.red)
            } else {
                content()
                    .foregroundColor(isItalicized ? .secondary : .primary)
            }
        }
        .font(font)
        .lineLimit(1)
        .italic(isItalicized)
    }
}

struct UnsettableTextView: View {
    let text: String
    var iconString: String? = nil
    var font: Font = .title3.bold()
    var isItalicized: Bool = false
    var fallbackText: String = "Unset"
    var fallbackIconString: String? = nil
    
    var body: some View {
        UnsettableView(
            isUnset: !text.isNotUnset(),
            font: font,
            isItalicized: isItalicized,
            fallbackText: fallbackText,
            fallbackIconString: fallbackIconString
        ) {
            HStack(spacing: 6) {
                if let icon = iconString {
                    IconView(iconString: icon, size: 16)
                }
                Text(text)
            }
        }
    }
}
