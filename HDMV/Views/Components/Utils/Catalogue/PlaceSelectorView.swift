//
//  PlaceSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.09.2025.
//


import SwiftUI
import SwiftData

struct PlaceSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedPlaceId: Int?
    
    // MARK: - Data Queries
    @Query(sort: [SortDescriptor(\City.name)])
    private var cities: [City]
    
    private var placesForSelectedCity: [Place] {
        guard let cityId = displayCityId else { return [] }
        let predicate = #Predicate<Place> { $0.city_id == cityId }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Place.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - State
    @State private var displayCityId: Int?
    @State private var initialPlace: Place?
    
    // MARK: - Initializer
    init(selectedPlaceId: Binding<Int?>) {
        self._selectedPlaceId = selectedPlaceId
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            if selectedPlaceId != nil && initialPlace == nil {
                uncachedPlaceView
            }
            cityPicker
            if displayCityId != nil {
                placePicker
            }
        }
        .onAppear(perform: initializeState)
        
    }
    
    // MARK: - Subviews
    private var uncachedPlaceView: some View {
        HStack {
            Text("Selected")
            Spacer()
            Text("Uncached")
                .bold()
                .foregroundStyle(.orange)
        }
    }
    
    private var cityPicker: some View {
        Picker("City", selection: $displayCityId) {
            Text("Select a City").tag(nil as Int?)
            ForEach(cities) { city in
                Text(city.name).tag(city.id as Int?)
            }
        }
    }
    
    private var placePicker: some View {
        Picker("Place", selection: $selectedPlaceId) {
            Text("Select a Place").tag(nil as Int?)
            ForEach(placesForSelectedCity) { place in
                Text(place.name).tag(place.id as Int?)
            }
            
            if let place = initialPlace,
               place.city_id == displayCityId,
               !placesForSelectedCity.contains(where: { $0.id == place.id }) {
                Text(place.name)
                    .foregroundStyle(.secondary)
                    .tag(place.id as Int?)
            }
        }
        .onChange(of: selectedPlaceId) { _, newPlaceId in
            self.initialPlace = fetchPlace(withId: newPlaceId)
        }
    }

    // MARK: - Logic
    private func fetchPlace(withId id: Int?) -> Place? {
        guard let placeId = id else { return nil }
        let predicate = #Predicate<Place> { $0.id == placeId }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    private func initializeState() {
        if let savedPlace = fetchPlace(withId: selectedPlaceId) {
            self.initialPlace = savedPlace
            self.displayCityId = savedPlace.city_id
        }
    }
}
