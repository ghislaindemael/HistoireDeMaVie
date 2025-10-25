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
    
    @StateObject var viewModel: ActivityInstanceDetailSheetViewModel
    
    let instance: ActivityInstance
    
    private var selectedActivity: Activity? {
        viewModel.editor.activity
    }
    
    init(
        instance: ActivityInstance,
        modelContext: ModelContext,
        availableTrips: [Trip],
        availableInteractions: [Interaction]
    ) {
        self.instance = instance
        _viewModel = StateObject(wrappedValue: ActivityInstanceDetailSheetViewModel(
            model: instance,
            modelContext: modelContext,
            trips: availableTrips,
            interactions: availableInteractions
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                TimeSection(editor: $viewModel.editor)
                
                basicsSection
                detailsSection
                if let activity = selectedActivity, activity.canLogDetails() {
                    specializedDetailsSection
                }
                
                
                if viewModel.editor.parent != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parent = nil
                        }
                    }
                }
                
                if !viewModel.unclaimedTrips.isEmpty && selectedActivity?.can(.create_trips) == true {
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
                
                if !viewModel.unclaimedInteractions.isEmpty &&
                    selectedActivity?.can(.create_interactions) == true
                    {
                    Section("Claim Interactions") {
                        ForEach(viewModel.unclaimedInteractions) { interaction in
                            InteractionRowView(interaction: interaction)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.claim(interaction: interaction, for: instance)
                                }
                        }
                    }
                }

            }
            .navigationTitle(selectedActivity?.name ?? "Edit Instance")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
                dismiss()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var basicsSection: some View {
        Section("Basics") {
            NavigationLink(destination: ActivitySelectorView(
                selectedActivity: $viewModel.editor.activity
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
        }
    }
    
    private var detailsSection: some View {
        Section("Details") {
            TextEditor(text: Binding(
                get: { viewModel.editor.details ?? "" },
                set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
            ))
            .lineLimit(3...)
        }
    }
    
    @ViewBuilder
    private var specializedDetailsSection: some View {
        
        VStack {
            if selectedActivity!.can(.log_food) {
                MealDetailsEditView(metadata: $viewModel.editor.decodedActivityDetails)
            }
            
            if selectedActivity!.can(.link_place) {
                PlaceSelectorView(selectedPlace: detailsPlaceBinding)
            }
        }
    }
    
    private var detailsPlaceBinding: Binding<Place?> {
        Binding<Place?>(
            get: {
                viewModel.editor.decodedActivityDetails?.place?.place
            },
            set: { newPlace in
                if viewModel.editor.decodedActivityDetails == nil {
                    viewModel.editor.decodedActivityDetails = ActivityDetails()
                }
                if viewModel.editor.decodedActivityDetails?.place == nil {
                    viewModel.editor.decodedActivityDetails?.place = PlaceDetails()
                }
                viewModel.editor.decodedActivityDetails?.place?.place = newPlace
                viewModel.editor.decodedActivityDetails?.place?.placeId = newPlace?.rid
            }
        )
    }
    
    
}


