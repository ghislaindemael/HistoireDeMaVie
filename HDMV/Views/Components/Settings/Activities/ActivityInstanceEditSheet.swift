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
                
                
                Section("Hierarchy") {
                    if editor.parent != nil {
                        Button("Remove from Parent", role: .destructive) {
                            editor.parent = nil
                        }
                    }
                }
                
                if selectedActivity?.can(.create_trip_legs) == true {
                    tripLegsSection
                    claimTripLegsSection
                }
                
                if selectedActivity?.can(.create_interactions) == true {
                    peopleInteractionsSection
                    claimInteractionsSection
                }
            }
            .navigationTitle(selectedActivity?.name ?? "New Activity")
            .sheet(item: $tripLegToEdit) { leg in
                TripLegDetailSheet(
                    tripLeg: leg,
                    modelContext: modelContext
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
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
                if activity.can(.log_food) {
                    MealDetailsEditView(metadata: $editor.decodedActivityDetails)
                }
                
                if activity.can(.link_place) {
                    PlaceSelectorView(
                        selectedPlaceId: Binding(
                            get: { editor.decodedActivityDetails?.place?.placeId },
                            set: { newValue in
                                if editor.decodedActivityDetails == nil {
                                    editor.decodedActivityDetails = ActivityDetails()
                                }
                                if editor.decodedActivityDetails?.place == nil {
                                    editor.decodedActivityDetails?.place = PlaceDetails()
                                }
                                editor.decodedActivityDetails?.place?.placeId = newValue
                            }
                        )
                    )
                }
            }
        }
    }
    
    private var tripLegsSection: some View {
        Section("Trip Legs") {
            ForEach(viewModel.tripLegs(for: instance.id)) { leg in                
                Button(action: { tripLegToEdit = leg }) {
                    TripLegRowView(
                        tripLeg: leg,
                        onEnd: {
                            viewModel.endTripLeg(leg: leg)
                        }
                    )
                }
            }
            
        }
        
    }
    
    private var claimTripLegsSection: some View {
        Section("Claim trip legs"){
            ForEach(viewModel.tripLegs) { leg in
                Button(action: { viewModel.claim(tripLeg: leg, for: instance) }) {
                    TripLegRowView(tripLeg: leg)
                }
            }
        }
    }
    
    private var peopleInteractionsSection: some View {
        Section("Trip Legs") {
            ForEach(viewModel.tripLegs(for: instance.id)) { leg in
                Button(action: { tripLegToEdit = leg }) {
                    TripLegRowView(
                        tripLeg: leg,
                        onEnd: {
                            viewModel.endTripLeg(leg: leg)
                        }
                    )
                }
            }
            
        }
        
    }
    
    private var claimInteractionsSection: some View {
        Section("Claim interactions"){
            ForEach(viewModel.interactions) { interaction in
                Button(action: { viewModel.claim(interaction: interaction, for: instance) }) {
                    PersonInteractionRowView(
                        interaction: interaction,
                        onEnd: {}
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


