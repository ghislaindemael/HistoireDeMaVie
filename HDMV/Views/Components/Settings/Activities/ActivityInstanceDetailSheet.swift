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
    
    private var selectedActivity: Activity? {
        editor.activity
    }
    
    init(instance: ActivityInstance, viewModel: MyActivitiesPageViewModel) {
        self.instance = instance
        self.viewModel = viewModel
        _editor = State(initialValue: ActivityInstanceEditor(from: instance))
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicsSection
                detailsSection
                if let activity = selectedActivity, activity.canLogDetails() {
                    specializedDetailsSection
                }
                
                
                if editor.parent != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            editor.parent = nil
                        }
                    }
                }
                
                if !viewModel.unclaimedTrips.isEmpty {
                    Section("Claim Trips") {
                        ForEach(viewModel.unclaimedTrips) { trip in
                            TripRowView(trip: trip)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.claim(trip: trip, for: instance)
                                }
                        }
                    }
                }

            }
            .navigationTitle(selectedActivity?.name ?? "New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                editor.apply(to: instance)
                instance.markAsModified()
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
            FullTimePicker(label: "End Time", selection: $editor.time_end)
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


