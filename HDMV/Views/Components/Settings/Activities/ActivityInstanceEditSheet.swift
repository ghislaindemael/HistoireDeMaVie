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
    
    let instance: ActivityInstance
    @State private var editor: ActivityInstanceEditor
    
    @State private var showEndTime: Bool
    @State private var tripLegToEdit: TripLeg?
    
    private var selectedActivity: Activity? {
        viewModel.findActivity(by: instance.activity_id)
    }
    
    init(instance: ActivityInstance, viewModel: MyActivitiesPageViewModel) {
        self.instance = instance
        self.viewModel = viewModel
        _editor = State(initialValue: ActivityInstanceEditor(from: instance))
        _showEndTime = State(initialValue: instance.time_end != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicsSection
                detailsSection
                if let activity = selectedActivity {
                    specializedDetailsSection(for: activity)
                }
                
                if selectedActivity?.can(.create_trip_legs) == true {
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
                instance.update(from: editor)
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
                selectedActivityId: $editor.activity_id
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
            FullTimePicker(label: "Start Time", selection: $editor.time_start)
            Toggle("End Time?", isOn: $showEndTime)
            if showEndTime {
                FullTimePicker(label: "End Time", selection: Binding(
                    get: { editor.time_end ?? Date() },
                    set: { editor.time_end = $0 }
                ))
            }
        }
    }
    
    private var detailsSection: some View {
        Section("Details") {
            TextEditor(text: Binding(
                get: { editor.details ?? "" },
                set: { editor.details = $0.isEmpty ? nil : $0 }
            ))
            .lineLimit(3...)
            Toggle("Set percentage?", isOn: showPercentageBinding)
            
            if editor.percentage != nil {
                Slider(value: percentageBinding, in: 0...100, step: 1)
            }
        }
    }
    
    private func specializedDetailsSection(for activity: Activity) -> some View {
        Section(header: Text("Activity Details")) {
            VStack {
                switch activity.type {
                    case .meal:
                        MealDetailsEditView(metadata: $editor.decodedActivityDetails)
                    case .reading:
                        //ReadingDetailsEditView(metadata: $instance.decodedActivityDetails)
                        EmptyView()
                    case .trip:
                        //TripDetailsEditView(metadata: $instance.decodedActivityDetails)
                        EmptyView()
                    case .generic, .none:
                        EmptyView()
                }
                
                if activity.permissions.contains("place") {
                    PlaceDetailsEditView(
                        metadata: $editor.decodedActivityDetails,
                        activityType: activity.type ?? .generic,
                        cities: viewModel.cities,
                        places: viewModel.places
                    )
                }
            }
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
    

    
    /// A binding to control the visibility of the percentage slider.
    /// It's 'on' if the percentage is not nil, and 'off' if it is.
    private var showPercentageBinding: Binding<Bool> {
        Binding<Bool>(
            get: { editor.percentage != nil },
            set: { isOn in
                if isOn {
                    editor.percentage = editor.percentage ?? 100
                } else {
                    editor.percentage = nil
                }
            }
        )
    }
    
    /// A binding that safely converts the model's `Int?` to a `Double` for the Slider.
    private var percentageBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(editor.percentage ?? 100) },
            set: { editor.percentage = Int($0) }
        )
    }
    
    
}


