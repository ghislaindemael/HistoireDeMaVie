//
//  TripLegDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct TripLegDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    private var tripLeg: TripLeg
        
    @State private var selectedStartCityId: Int?
    @State private var selectedEndCityId: Int?
    @State private var showEndTime: Bool
    
    @State private var editor: TripLegEditor
    
    @State private var isShowingPathSelector = false
    
    @Query(filter: #Predicate<Path> { $0.cache == true }) private var allPaths: [Path]
    
    init(tripLeg: TripLeg) {
        self.tripLeg = tripLeg
        _showEndTime = State(initialValue: tripLeg.time_end != nil)
        _editor = State(initialValue: TripLegEditor(tripLeg: tripLeg))
    }
    
    var body: some View {
        NavigationView {
            Form {
                timeSection
                vehicleSection
                
                Section("Start Place") {
                    PlaceSelectorView(selectedPlaceId: $editor.place_start_id)
                }
                Section("End Place") {
                    PlaceSelectorView(selectedPlaceId: $editor.place_end_id)
                }
                pathSection
                detailsSection
            }
            .navigationTitle("Trip Leg Details")
            .standardSheetToolbar(
                onDone: {
                    editor.apply(to: tripLeg)
                    tripLeg.syncStatus = .local
                    try? modelContext.save()
                    dismiss()
                }
            )
            .sheet(isPresented: $isShowingPathSelector) {
                PathSelectorSheet { selectedPathId in
                    editor.path_id = selectedPathId
                }
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var timeSection: some View {
        Section(header: Text("Time")) {
            FullTimePicker(label: "Start Time", selection: $editor.time_start)
            Toggle("End Time?", isOn: $showEndTime)
            if showEndTime {
                FullTimePicker(label: "End Time", selection: Binding(
                    get: { tripLeg.time_end ?? Date() },
                    set: { tripLeg.time_end = $0 }
                ))
            }
        }
    }
    
    private var vehicleSection: some View {
        Section("Vehicle") {
            VehicleSelectorView(
                selectedVehicleId: $editor.vehicle_id,
                amDriver: $editor.am_driver
            )
        }
    }
    
    private var pathSection: some View {
        Section(header: Text("Paths")) {
            PathDisplayView(pathId: editor.path_id)

            Button(action: { isShowingPathSelector = true }) {
                Label("Select path", systemImage: "plus.circle.fill")
            }
        }
    }
            
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            TextEditor(text: Binding(
                get: { tripLeg.details ?? "" },
                set: { tripLeg.details = $0.isEmpty ? nil : $0 }
            ))
            .frame(minHeight: 100)
        }
    }
    
    
    
}
