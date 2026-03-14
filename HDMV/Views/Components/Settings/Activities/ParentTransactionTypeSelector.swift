//
//  ParentTransactionTypeSelector.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//

import SwiftUI

struct ParentTransactionTypeSelector: View {
    let types: [TransactionType]
    @Binding var selectedParent: TransactionType?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Button("Top Level (No Parent)") {
                selectedParent = nil
                dismiss()
            }
            
            OutlineGroup(types, children: \.optionalChildren) { type in
                
                Button(action: {
                    selectedParent = type
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: type.icon ?? "")
                            .foregroundStyle(.primary)
                        Text(type.name)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Select Parent")
    }
}
