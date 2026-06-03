//
//  TransitLineSelectorSheet.swift
//  HDMV
//

import SwiftUI
import SwiftData

struct TransitLineSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \TransitLine.name)
    private var lines: [TransitLine]
    
    var onSelect: (TransitLine) -> Void
    
    var body: some View {
        NavigationView {
            List {
                if lines.isEmpty {
                    ContentUnavailableView("No Transit Lines", systemImage: "tram", description: Text("Create a transit line first."))
                } else {
                    ForEach(lines) { line in
                        Button {
                            onSelect(line)
                            dismiss()
                        } label: {
                            HStack {
                                Text(line.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Transit Line")
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
