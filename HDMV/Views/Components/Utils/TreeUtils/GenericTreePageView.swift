//
//  GenericTreePageView.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import SwiftUI

struct GenericTreePageView<T: TreeSelectable & Identifiable, RowView: View, SheetView: View>: View {
    let title: String
    let items: [T]
    let childrenKeyPath: KeyPath<T, [T]?>
    let isLoading: Bool
    
    // Actions
    let onRefresh: () async -> Void
    let onSync: () async -> Void
    let onAdd: () -> Void
    
    // UI Builders
    @ViewBuilder let rowContent: (T) -> RowView
    @ViewBuilder let sheetContent: (T) -> SheetView
    
    @State private var itemToEdit: T?
    
    var body: some View {
        List {
            OutlineGroup(items, children: childrenKeyPath) { item in
                Button(action: {
                    itemToEdit = item
                }) {
                    rowContent(item)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(title)
        .simpleLogToolbar(
            refreshAction: onRefresh,
            syncAction: onSync,
            onAdd: onAdd
        )
        .sheet(item: $itemToEdit) { item in
            sheetContent(item)
        }
        .syncingOverlay(isLoading)
    }
}
