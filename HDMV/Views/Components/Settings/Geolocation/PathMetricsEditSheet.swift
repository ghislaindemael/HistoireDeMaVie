//
//  PathMetricsEditSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.11.2025.
//


import SwiftUI

struct PathMetricsEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var metrics: PathMetrics
    
    var onSave: (PathMetrics) -> Void
    
    init(currentMetrics: PathMetrics?, onSave: @escaping (PathMetrics) -> Void) {
        _metrics = State(initialValue: currentMetrics ?? PathMetrics())
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("", value: $metrics.distance, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("m").foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Elevation Gain (+)")
                        Spacer()
                        TextField("", value: $metrics.elevationGain, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("m").foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Elevation Loss (-)")
                        Spacer()
                        TextField("", value: $metrics.elevationLoss, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("m").foregroundStyle(.secondary)
                    }
                    
                    TextEditor(text: Binding<String>(
                        get: { metrics.pathDescription ?? "" },
                        set: { metrics.pathDescription = $0.isEmpty ? nil : $0 }
                    ))
                    .lineLimit(5)
                }
            }
            .navigationTitle("Custom Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar {
                onSave(metrics)
                dismiss()
            }
        }
    }
}
