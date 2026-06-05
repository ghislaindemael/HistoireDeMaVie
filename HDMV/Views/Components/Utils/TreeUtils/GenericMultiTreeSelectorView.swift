//
//  GenericMultiTreeSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//


import SwiftUI

struct GenericMultiTreeSelectorView<T: TreeSelectable & SyncableModel>: View {
    @Environment(\.dismiss) private var dismiss
    
    let items: [T]
    let childrenKeyPath: KeyPath<T, [T]?>
    
    @Binding var selections: [Int]
    
    let title: String
    
    var body: some View {
        List {
            Button("Clear Selection") {
                selections.removeAll()
            }
            .foregroundColor(.red)
            
            OutlineGroup(items, children: childrenKeyPath) { item in
                Button(action: {
                    if let rid = item.rid {
                        if selections.contains(rid) {
                            selections.removeAll(where: { $0 == rid })
                        } else {
                            selections.append(rid)
                        }
                    }
                }) {
                    HStack {
                        IconView(iconString: item.icon ?? "")
                        Text(item.name)
                        Spacer()
                        if let rid = item.rid, selections.contains(rid) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(title)
    }
}
