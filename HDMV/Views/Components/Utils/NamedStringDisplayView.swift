//
//  NamedStringDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 18.10.2025.
//

import SwiftUI

struct NamedStringDisplayView: View {
    let name: String
    let value: String?
    let unsetLabel: String
    let unsetTint: Color
    
    init(name: String, value: String?, unsetLabel: String? = nil, unsetTint: Color? = nil) {
        self.name = name
        self.value = value
        self.unsetLabel = unsetLabel ?? "TOSET"
        self.unsetTint = unsetTint ?? .red
    }
    
    var body: some View {
        if let value = value {
            Text("\(name): \(value)")
        } else {
            Text("\(name): \(unsetLabel)")
                .bold()
                .foregroundStyle(unsetTint)
        }
    }
}
