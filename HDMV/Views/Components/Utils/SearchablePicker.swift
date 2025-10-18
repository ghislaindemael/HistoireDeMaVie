//
//  SearchablePicker.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.06.2025.
//


import SwiftUI

struct SearchablePicker<T: Identifiable & Hashable>: View where T: CustomStringConvertible {
    let title: String
    let items: [T]
    @Binding var selection: T?
    
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filteredItems: [T] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredItems) { item in
                Button(action: {
                    selection = item
                    dismiss()
                }) {
                    Text(item.description)
                }
                .tint(.primary)
            }
            .navigationTitle(title)
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

