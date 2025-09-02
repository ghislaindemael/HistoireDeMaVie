//
//  ActivityInstanceDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct ActivityInstanceDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var viewModel: MyActivitiesPageViewModel
    
    @Bindable var instance: ActivityInstance
    
    @State private var showEndTime: Bool
    @State private var tripLegToEdit: TripLeg?
    
    private var selectedActivity: Activity? {
        viewModel.findActivity(by: instance.activity_id)
    }
    
    init(instance: ActivityInstance, viewModel: MyActivitiesPageViewModel) {
        self.instance = instance
        self.viewModel = viewModel
        _showEndTime = State(initialValue: instance.time_end != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicsSection
                detailsSection
                if let activity = selectedActivity, activity.type != .generic {
                    specializedDetailsSection(for: activity)
                }
                
                if selectedActivity?.canCreateTripLegs == true {
                    tripLegsSection
                    if !viewModel.unassignedTripLegs().isEmpty {
                        claimTripLegsSection
                    }
                }
            }
            .navigationTitle(selectedActivity?.name ?? "New Activity")
            .sheet(item: $tripLegToEdit) { leg in
                TripLegDetailSheet(
                    tripLeg: leg,
                    vehicles: viewModel.vehicles,
                    cities: viewModel.cities,
                    places: viewModel.places
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar(isFormValid: true) {
                instance.syncStatus = .local
                if !showEndTime {
                    instance.time_end = nil
                }
                try? modelContext.save()
                dismiss()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var basicsSection: some View {
        Section("Basics") {
            NavigationLink(destination: ActivitySelectorView(
                activityTree: viewModel.activityTree,
                selectedActivityId: $instance.activity_id
            )) {
                HStack {
                    Text("Select Activity")
                    Spacer()
                    if let activity = selectedActivity {
                        Text(activity.name)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            FullTimePicker(label: "Start Time", selection: $instance.time_start)
            Toggle("End Time?", isOn: $showEndTime)
            if showEndTime {
                FullTimePicker(label: "End Time", selection: Binding(
                    get: { instance.time_end ?? Date() },
                    set: { instance.time_end = $0 }
                ))
            }
        }
    }
    
    private var detailsSection: some View {
        Section("Details") {
            TextEditor(text: Binding(
                get: { instance.details ?? "" },
                set: { instance.details = $0.isEmpty ? nil : $0 }
            ))
            .lineLimit(3...)
            Toggle("Set percentage?", isOn: showPercentageBinding)
            
            if instance.percentage != nil {
                Slider(value: percentageBinding, in: 0...100, step: 1)
            }
        }
    }
    
    private func specializedDetailsSection(for activity: Activity) -> some View {
        Section(header: Text("Activity Details")) {
            specializedDetailsView(for: activity)
        }
    }
    
    private var tripLegsSection: some View {
        Section("Trip Legs") {
            ForEach(viewModel.tripLegs(for: instance.id)) { leg in
                let instanceTripLegs = viewModel.tripLegs(for: instance.id)
                let instancePlaces = viewModel.tripsPlaces(for: instanceTripLegs)
                
                Button(action: { tripLegToEdit = leg }) {
                    TripLegRowView(
                        tripLeg: leg,
                        vehicle: viewModel.findVehicle(by: leg.vehicle_id),
                        places: instancePlaces
                    )
                }
            }
            
        }
        
    }
    
    private var claimTripLegsSection: some View {
        Section("Claim trip legs"){
            ForEach(viewModel.unassignedTripLegs()) { leg in
                Button(action: { viewModel.claim(tripLeg: leg, for: instance) }) {
                    TripLegRowView(
                        tripLeg: leg,
                        vehicle: viewModel.findVehicle(by: leg.vehicle_id),
                        places: viewModel.tripsPlaces(for: [leg])
                    )
                }
            }
        }
    }
    
    
    
    @ViewBuilder
    private func specializedDetailsView(for activity: Activity) -> some View {
        switch activity.type {
            case .meal:
                MealDetailsEditView(metadata: $instance.decodedActivityDetails)
            case .reading:
                Text("Reading details editor")
            case .generic:
                Text("Additional details")
                .frame(minHeight: 100)
            default:
                EmptyView()
        }
    }
    
    /// A binding to control the visibility of the percentage slider.
    /// It's 'on' if the percentage is not nil, and 'off' if it is.
    private var showPercentageBinding: Binding<Bool> {
        Binding<Bool>(
            get: { instance.percentage != nil },
            set: { isOn in
                if isOn {
                    instance.percentage = instance.percentage ?? 100
                } else {
                    instance.percentage = nil
                }
            }
        )
    }
    
    /// A binding that safely converts the model's `Int?` to a `Double` for the Slider.
    private var percentageBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(instance.percentage ?? 100) },
            set: { instance.percentage = Int($0) }
        )
    }
    
    
}

// MARK: - Hierarchical Activity Selector View
private struct ActivitySelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let activityTree: [Activity]
    @Binding var selectedActivityId: Int?
    
    var body: some View {
        List {
            Button("None") {
                selectedActivityId = nil
                dismiss()
            }
            
            OutlineGroup(activityTree, children: \.optionalChildren) { activity in
                Button(action: {
                    selectedActivityId = activity.id
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: activity.icon)
                        Text(activity.name)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Select an Activity")
    }
}
