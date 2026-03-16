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
            List {
                // MARK: - 1. Date Selector Section
                Section {
                    DatePicker(
                        "Workout Date",
                        selection: $viewModel.filterDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                
                // MARK: - 2. Workouts List
                Section {
                    if viewModel.workouts.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "No Workouts",
                            systemImage: "figure.run.slash",
                            description: Text("We couldn't find any Apple Health workouts for this date.")
                        )
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.workouts, id: \.uuid) { workout in
                            WorkoutRow(
                                workout: workout,
                                isImported: viewModel.isImported(workout),
                                onImport: { target in
                                    Task {
                                        withAnimation(.snappy) {
                                            viewModel.isLoading = true
                                        }
                                        
                                        await viewModel.importWorkout(workout, as: target)
                                        
                                        withAnimation(.snappy) {
                                            viewModel.isLoading = false
                                        }
                                    }
                                }
                            )
                        }
                    }
                } header: {
                    if !viewModel.workouts.isEmpty {
                        Text("Available to Import")
                    }
                }
            }
            .listStyle(.insetGrouped)
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
                    ProgressView("Syncing with Health...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - Polished Row View
struct WorkoutRow: View {
    let workout: HKWorkout
    let isImported: Bool
    let onImport: (ImportTarget) -> Void
    
    private var durationString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: workout.duration) ?? ""
    }
        
    private var workoutIcon: String {
        switch workout.workoutActivityType {
            case .running: return "figure.run"
            case .walking: return "figure.walk"
            case .cycling: return "figure.outdoor.cycle"
            case .swimming: return "figure.pool.swim"
            case .elliptical: return "figure.elliptical"
            case .hiking: return "figure.hiking"
            case .tennis, .tableTennis, .badminton, .squash, .pickleball: return "figure.tennis"
            default: return "figure.run.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            
            Image(systemName: workoutIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.blue.gradient, in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutActivityType.name)
                    .font(.headline)
                
                HStack(spacing: 6) {
                    Text(DateFormatter.timeWithSeconds.string(from:workout.startDate))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(DateFormatter.timeWithSeconds.string(from:workout.endDate))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Label(durationString, systemImage: "clock")
                        .foregroundStyle(.primary)
                    
                    if let distance = workout.totalDistance?.doubleValue(for: .meter()), distance > 0 {
                        Label("\(String(format: "%.2f", distance / 1000)) km", systemImage: "location.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .font(.caption)
                .bold()
                .padding(.top, 2)
            }
            
            Spacer()
            
            if isImported {
                Text("Imported")
                    .font(.subheadline).bold()
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
            } else {
                Menu {
                    Button {
                        onImport(.trip)
                    } label: {
                        Label("Import as Trip", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    }
                    Button {
                        onImport(.activity)
                    } label: {
                        Label("Import as Activity", systemImage: "square.stack.3d.up.fill")
                    }
                } label: {
                    Text("Import")
                        .font(.subheadline).bold()
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
