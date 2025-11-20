//
//  PathMetricsEditSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.11.2025.
//


import SwiftUI

struct PathMetricsEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Local state for editing (prevents view thrashing)
    @State private var metrics: PathMetrics
    
    // Callback to return the saved value
    var onSave: (PathMetrics) -> Void
    
    init(currentMetrics: PathMetrics?, onSave: @escaping (PathMetrics) -> Void) {
        // Initialize with existing metrics OR a blank object
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
                        TextField("0", value: $metrics.distance, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("m").foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Elevation Gain (+)")
                        Spacer()
                        TextField("0", value: $metrics.elevationGain, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("m").foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Elevation Loss (-)")
                        Spacer()
                        TextField("0", value: $metrics.elevationLoss, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("m").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Custom Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(metrics) // Send data back
                        dismiss()
                    }
                }
            }
        }
    }
}