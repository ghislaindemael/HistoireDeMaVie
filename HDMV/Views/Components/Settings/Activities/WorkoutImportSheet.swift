//
//  WorkoutImportSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.03.2026.
//


import SwiftUI
import HealthKit
import SwiftData

struct WorkoutImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutImportViewModel
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: WorkoutImportViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("Select Date", selection: $viewModel.filterDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                
                List {
                    if viewModel.workouts.isEmpty && !viewModel.isLoading {
                        Text("No workouts found in Apple Health for this date.")
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    }
                    
                    ForEach(viewModel.workouts, id: \.uuid) { workout in
                        WorkoutRow(
                            workout: workout,
                            isImported: viewModel.isImported(workout),
                            onImport: { viewModel.importWorkout(workout) }
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Import Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: viewModel.filterDate) {
                Task { await viewModel.loadData() }
            }
            .onAppear {
                Task { await viewModel.loadData() }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// Custom Row for the Workouts
struct WorkoutRow: View {
    let workout: HKWorkout
    let isImported: Bool
    let onImport: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutActivityType.name)
                    .font(.headline)
                
                HStack {
                    Text(workout.startDate, style: .time)
                    Image(systemName: "arrow.right")
                    Text(workout.endDate, style: .time)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                    Text("\(String(format: "%.2f", distance / 1000)) km")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Button(action: onImport) {
                Text(isImported ? "Imported" : "Import")
                    .font(.subheadline)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isImported ? Color.gray.opacity(0.2) : Color.blue)
                    .foregroundColor(isImported ? .secondary : .white)
                    .cornerRadius(20)
            }
            .disabled(isImported)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
