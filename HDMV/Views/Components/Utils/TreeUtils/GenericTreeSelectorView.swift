//
//  GenericTreeSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import SwiftUI

struct GenericTreeSelectorView<T: TreeSelectable>: View {
    @Environment(\.dismiss) private var dismiss
    
    let items: [T]
    let childrenKeyPath: KeyPath<T, [T]?>
    
    @Binding var selection: T?
    
    // Customizable text
    let title: String
    let noneButtonText: String
    
    var body: some View {
        List {
            Button(noneButtonText) {
                selection = nil
                dismiss()
            }
            
            OutlineGroup(items, children: childrenKeyPath) { item in
                Button(action: {
                    selection = item
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: item.icon ?? "")
                        Text(item.name)
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(title)
    }
}
