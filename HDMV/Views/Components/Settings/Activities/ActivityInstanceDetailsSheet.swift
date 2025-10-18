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
    @State private var tripToEdit: Trip?
    @State private var interactionToEdit: PersonInteraction?
    
    private var selectedActivity: Activity? {
        editor.activity
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
                if let activity = selectedActivity, activity.canLogDetails() {
                    specializedDetailsSection
                }
                
                Section("Hierarchy") {
                    if editor.parent != nil {
                        Button("Remove from Parent", role: .destructive) {
                            editor.parent = nil
                        }
                    }
                }

            }
            .navigationTitle(selectedActivity?.name ?? "New Activity")
            .sheet(item: $tripToEdit) { trip in
                TripDetailSheet(
                    trip: trip,
                    modelContext: modelContext
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                editor.apply(to: instance)
                instance.markAsModified()
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
                selectedActivity: $editor.activity
            )) {
                HStack {
                    Text("Select Activity")
                    Spacer()
                    if let activity = selectedActivity {
                        Text(activity.name ?? "TOSET")
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
            Slider(value: percentageBinding, in: 0...100, step: 1)
                .tint(percentageBinding.wrappedValue == 100 ? .gray : .accentColor)

        }
    }
    
    @ViewBuilder
    private var specializedDetailsSection: some View {
        
        VStack {
            if selectedActivity!.can(.log_food) {
                MealDetailsEditView(metadata: $editor.decodedActivityDetails)
            }
            
            if selectedActivity!.can(.link_place) {
                PlaceSelectorView(selectedPlace: detailsPlaceBinding)
            }
        }
    }

    
    /// A binding that safely converts the model's `Int?` to a `Double` for the Slider.
    private var percentageBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(editor.percentage) },
            set: { editor.percentage = Int($0) }
        )
    }
    
    private var detailsPlaceBinding: Binding<Place?> {
        Binding<Place?>(
            get: {
                editor.decodedActivityDetails?.place?.place
            },
            set: { newPlace in
                if editor.decodedActivityDetails == nil {
                    editor.decodedActivityDetails = ActivityDetails()
                }
                if editor.decodedActivityDetails?.place == nil {
                    editor.decodedActivityDetails?.place = PlaceDetails()
                }
                editor.decodedActivityDetails?.place?.place = newPlace
                editor.decodedActivityDetails?.place?.placeId = newPlace?.rid
            }
        )
    }
    
    
}


