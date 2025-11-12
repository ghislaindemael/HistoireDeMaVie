//
//  UnclaimedItemsView.swift
//  HDMV
//
//  Created by Ghislain Demael on 12.11.2025.
//


import SwiftUI
import SwiftData

struct UnclaimedItemsView<Item: LogModel>: View {
    
    let title: String
    let items: [Item]
    let rowBuilder: (Item) -> any View
    let onClaim: (Item) -> Void
    
    let isDisabled: Bool
    
    init(
        title: String,
        items: [Item],
        isDisabled: Bool = false,
        onClaim: @escaping (Item) -> Void,
        @ViewBuilder rowBuilder: @escaping (Item) -> any View
    ) {
        self.title = title
        self.items = items
        self.isDisabled = isDisabled
        self.onClaim = onClaim
        self.rowBuilder = rowBuilder
    }
    
    var body: some View {
        if !items.isEmpty && !isDisabled {
            Section(title) {
                ForEach(items) { item in
                    Button(action: { onClaim(item) }) {
                        AnyView(rowBuilder(item))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
