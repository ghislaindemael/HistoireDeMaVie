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
    var fetchArchivedAction: (() async -> Void)? = nil
    var purgeArchivedAction: (() async -> Void)? = nil
    var onDeleteItem: ((T) -> Void)? = nil
    
    // UI Builders
    @ViewBuilder let rowContent: (T) -> RowView
    @ViewBuilder let sheetContent: (T) -> SheetView
    
    @State private var itemToEdit: T?
    
    private var unsetItems: [T] {
        items.filter { $0.name.isUnset() }
    }
    
    private var validItems: [T] {
        items.filter { $0.name.isNotUnset() }
    }
    
    var body: some View {
        List {
            if !unsetItems.isEmpty {
                Section("Needs Configuration / Unset") {
                    ForEach(unsetItems) { item in
                        itemRow(item)
                    }
                }
            }
            
            Section {
                OutlineGroup(validItems, children: childrenKeyPath) { item in
                    itemRow(item)
                }
            }
        }
        .navigationTitle(title)
        .simpleLogToolbar(
            refreshAction: onRefresh,
            syncAction: onSync,
            onAdd: onAdd,
            fetchArchivedAction: fetchArchivedAction,
            purgeArchivedAction: purgeArchivedAction
        )
        .sheet(item: $itemToEdit) { item in
            sheetContent(item)
        }
        .syncingOverlay(isLoading)
    }
    
    @ViewBuilder
    private func itemRow(_ item: T) -> some View {
        Button(action: {
            itemToEdit = item
        }) {
            rowContent(item)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            if let onDeleteItem = onDeleteItem {
                Button(role: .destructive) {
                    onDeleteItem(item)
                } label: {
                    Label("Delete Cache", systemImage: "trash")
                }
            }
        }
    }
}
