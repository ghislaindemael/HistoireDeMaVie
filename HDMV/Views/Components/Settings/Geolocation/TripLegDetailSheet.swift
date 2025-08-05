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
    
    let vehicles: [Vehicle]
    let cities: [City]
    let places: [Place]
    
    @State private var selectedStartCityId: Int?
    @State private var selectedEndCityId: Int?
    @State private var showEndTime: Bool
    
    init(tripLeg: TripLeg, vehicles: [Vehicle], cities: [City], places: [Place]) {
        self.tripLeg = tripLeg
        self.vehicles = vehicles
        self.cities = cities
        self.places = places
        _showEndTime = State(initialValue: tripLeg.time_end != nil)
    }
    
    private var isSelectedVehicleCar: Bool {
        guard let vehicleId = tripLeg.vehicle_id,
              let vehicle = vehicles.first(where: { $0.id == vehicleId })
        else {
            return false
        }
        return vehicle.type == 1
    }
    
    var body: some View {
        NavigationView {
            Form {
                timeSection
                vehicleSection
                startPlaceSection
                endPlaceSection
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
            .onAppear(perform: setupInitialCitySelections)
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
            Picker("Vehicle", selection: $tripLeg.vehicle_id) {
                Text("None").tag(nil as Int?)
                ForEach(vehicles) { vehicle in
                    Text(vehicle.name).tag(vehicle.id as Int?)
                }
            }
            if isSelectedVehicleCar {
                Toggle("Am I the driver", isOn: $tripLeg.am_driver)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var startPlaceSection: some View {
        Section(header: Text("Start Place")) {
            Picker("City", selection: $selectedStartCityId) {
                Text("Select City").tag(nil as Int?)
                ForEach(cities) { city in
                    Text(city.name).tag(city.id as Int?)
                }
            }
            .onChange(of: selectedStartCityId) { oldValue, newValue in
                if oldValue != nil {
                    tripLeg.place_start_id = nil
                }
            }
            
            if selectedStartCityId != nil {
                Picker("Place", selection: $tripLeg.place_start_id) {
                    Text("Select Place").tag(nil as Int?)
                    ForEach(places.filter { $0.city_id == selectedStartCityId }) { place in
                        Text(place.name).tag(place.id as Int?)
                    }
                }
            }
        }
    }
    
    private var endPlaceSection: some View {
        Section(header: Text("End Place")) {
            Picker("City", selection: $selectedEndCityId) {
                Text("Select City").tag(nil as Int?)
                ForEach(cities) { city in
                    Text(city.name).tag(city.id as Int?)
                }
            }
            .onChange(of: selectedEndCityId) { oldValue, newValue in
                if oldValue != nil {
                    tripLeg.place_end_id = nil
                }
            }
            
            if selectedEndCityId != nil {
                Picker("Place", selection: $tripLeg.place_end_id) {
                    Text("Select Place").tag(nil as Int?)
                    ForEach(places.filter { $0.city_id == selectedEndCityId }) { place in
                        Text(place.name).tag(place.id as Int?)
                    }
                }
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
    
    // MARK: - Helper Methods
    
    /// Sets the initial city selection based on the trip leg's start and end places.
    private func setupInitialCitySelections() {
        if let startPlace = places.first(where: { $0.id == tripLeg.place_start_id }) {
            selectedStartCityId = startPlace.city_id
        }
        if let endPlace = places.first(where: { $0.id == tripLeg.place_end_id }) {
            selectedEndCityId = endPlace.city_id
        }
    }
}
