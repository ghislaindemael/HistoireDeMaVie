//
//  UnsettableTextView.swift
//  HDMV
//
//  Created by Ghislain Demael on 18.06.2026.
//

import SwiftUI

struct UnsettableTextView: View {
    let text: String
    var font: Font = .title3.bold()
    var isItalicized: Bool = false
    var fallbackText: String = "Unset"
    
    var body: some View {
        Text(text.isNotUnset() ? text : fallbackText)
            .font(font)
            .lineLimit(1)
            .italic(isItalicized)
            .foregroundColor(text.isNotUnset() ? (isItalicized ? .secondary : .primary) : .red)
    }
}
