//
//  DataActivityOptionSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataActivityOptionSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DataActivityOption.name) private var allOptions: [DataActivityOption]
    
    let onSelect: (DataActivityOption) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allOptions) { option in
                    Button {
                        onSelect(option)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(option.name)
                                    .font(.headline)
                                Text(option.slug)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(option.typeRaw.capitalized)
                                .font(.caption2)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Option")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
