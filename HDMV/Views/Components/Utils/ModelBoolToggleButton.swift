//
//  ModelBoolToggleButton.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//


import SwiftUI
import SwiftData

struct ModelBoolToggleButton: View {
    let isOn: Bool
    let onSymbol: String
    let offSymbol: String
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(.snappy) {
                action()
            }
        } label: {
            Image(systemName: isOn ? onSymbol : offSymbol)
                .font(.system(size: 20))
                .foregroundStyle(isOn ? .blue : .red)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }
}

