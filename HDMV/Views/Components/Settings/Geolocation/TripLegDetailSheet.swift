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
    
    @Bindable var tripLeg: TripLeg
        
    @State private var selectedStartCityId: Int?
    @State private var selectedEndCityId: Int?
    @State private var showEndTime: Bool
    
    init(tripLeg: TripLeg) {
        self.tripLeg = tripLeg
        _showEndTime = State(initialValue: tripLeg.time_end != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                timeSection
                vehicleSection
                
                Section(header: Text("Start Place")) {
                    PlaceSelectorView(selectedPlaceId: $tripLeg.place_start_id)
                }
                Section(header: Text("End Place")) {
                    PlaceSelectorView(selectedPlaceId: $tripLeg.place_end_id)
                }
                
                detailsSection
            }
            .navigationTitle("Trip Leg Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        tripLeg.syncStatus = .local
                        if !showEndTime {
                            tripLeg.time_end = nil
                        }
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var timeSection: some View {
        Section(header: Text("Time")) {
            FullTimePicker(label: "Start Time", selection: $tripLeg.time_start)
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
        Section(header: Text("Vehicle")) {
            VehicleSelectorView(
                selectedVehicleId: $tripLeg.vehicle_id,
                amDriver: $tripLeg.am_driver
            )
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
