//
//  TripDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.06.2025.
//

import SwiftUI
import SwiftData

struct TripDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let trip: TripDisplayModel
    let onSave: (Trip) -> Void
    
    // --- Local State for Editing ---
    @State private var time_start: Date
    @State private var time_end: Date?
    @State private var hasEndTime: Bool
    @State private var vehicle_id: Int?
    @State private var place_start_id: Int?
    @State private var place_end_id: Int?
    @State private var am_driver: Bool
    @State private var path_str: String?
    @State private var details: String?
    
    @State private var selectedStartCityId: Int?
    @State private var selectedEndCityId: Int?
    
    // --- Queries for Pickers ---
    @Query(sort: [SortDescriptor<Vehicle>(\.name)]) var vehicles: [Vehicle]
    @Query(sort: [SortDescriptor<City>(\.rank), SortDescriptor<City>(\.name)]) var cities: [City]
    @Query(sort: [SortDescriptor<Place>(\.localName)]) var places: [Place]
    
    // --- Initializer ---
    init(trip: TripDisplayModel, onSave: @escaping (Trip) -> Void) {
        self.trip = trip
        self.onSave = onSave
        
        _time_start = State(initialValue: trip.time_start)
        _time_end = State(initialValue: trip.time_end)
        _hasEndTime = State(initialValue: trip.time_end != nil)
        _vehicle_id = State(initialValue: trip.vehicle_id)
        _place_start_id = State(initialValue: trip.place_start_id)
        _place_end_id = State(initialValue: trip.place_end_id)
        _am_driver = State(initialValue: trip.am_driver)
        _path_str = State(initialValue: trip.path_str)
        _details = State(initialValue: trip.details)
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
            .navigationTitle("Trip Details")
            .toolbar { toolbarContent }
            .onAppear(perform: setupInitialCitySelections)
            .onChange(of: hasEndTime) { _, newHasEnd in
                handleEndTimeToggle(newHasEnd)
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var timeSection: some View {
        Section(header: Text("Time")) {
            FullTimePicker(label:"Start Time", selection: $time_start)
            Toggle("Has End Time", isOn: $hasEndTime.animation())
            
            if hasEndTime {
                FullTimePicker(label: "End Time", selection: Binding(
                    get: { self.time_end ?? Date() },
                    set: { self.time_end = $0 }
                ))
            }
        }
    }
    
    private var vehicleSection: some View {
        Section(header: Text("Vehicle")) {
            Picker("Vehicle", selection: $vehicle_id) {
                Text("None").tag(nil as Int?)
                ForEach(vehicles) { vehicle in
                    Text(vehicle.name).tag(vehicle.id as Int?)
                }
            }
            Toggle("Am I the driver", isOn: $am_driver)
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
                    place_start_id = nil
                }
            }
            
            if selectedStartCityId != nil {
                Picker("Place", selection: $place_start_id) {
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
                    place_end_id = nil
                }
            }
            
            if selectedEndCityId != nil {
                Picker("Place", selection: $place_end_id) {
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
            // Using a custom binding to handle optional strings for TextEditor
            TextEditor(text: $path_str.orEmpty)
                .frame(minHeight: 60)
                .cornerRadius(8)
            TextEditor(text: $details.orEmpty)
                .frame(minHeight: 60)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                saveTrip()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialCitySelections() {
        if let startPlace = places.first(where: { $0.id == trip.place_start_id }) {
            selectedStartCityId = startPlace.city_id
        }
        if let endPlace = places.first(where: { $0.id == trip.place_end_id }) {
            selectedEndCityId = endPlace.city_id
        }
    }
    
    private func handleEndTimeToggle(_ newHasEnd: Bool) {
        if !newHasEnd {
            time_end = nil
        } else if time_end == nil {
            time_end = Date()
        }
    }
    
    private func saveTrip() {
        // Create the updated trip object with all properties
        let savedTrip = Trip(
            id: trip.id,
            time_start: time_start,
            time_end: hasEndTime ? time_end : nil,
            vehicle_id: vehicle_id,
            place_start_id: place_start_id,
            place_end_id: place_end_id,
            am_driver: am_driver,      // Included
            path_str: path_str,        // Included
            details: details,          // Included
            syncStatus: .local
        )
        onSave(savedTrip)
        dismiss()
    }
}

// MARK: - Binding Extension

// This extension provides a convenient way to bind a TextEditor to an optional String.
private extension Binding where Value == String? {
    var orEmpty: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
