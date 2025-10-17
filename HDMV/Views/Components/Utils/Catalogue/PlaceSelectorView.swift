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
    
    @Binding var selectedPlace: Place?
    
    // MARK: - Data Queries
    @Query(FetchDescriptor<City>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.name)]))
    private var cities: [City]
    
    private var placesForSelectedCity: [Place] {
        guard let cityId = displayCityId else { return [] }
        let predicate = #Predicate<Place> { $0.cityRid == cityId && $0.name != nil }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Place.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - State
    @State private var displayCityId: Int?
    @State private var initialPlace: Place?
    
    // MARK: - Initializer
    init(selectedPlace: Binding<Place?>) {
        self._selectedPlace = selectedPlace
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            if selectedPlace != nil && initialPlace == nil {
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
                Text(city.name!).tag(city.rid as Int?)
            }
        }
    }
    
    private var placePicker: some View {
        Picker("Place", selection: $selectedPlace) {
            Text("Select a Place").tag(nil as Place?)
            ForEach(placesForSelectedCity) { place in
                Text(place.name!).tag(place as Place?)
            }
        }
        .onChange(of: selectedPlace) { _, newPlace in
            self.initialPlace = selectedPlace
        }
    }

    // MARK: - Logic
    private func fetchPlace(withId id: Int?) -> Place? {
        guard let placeId = id else { return nil }
        let predicate = #Predicate<Place> { $0.rid == placeId }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    private func initializeState() {
        if let savedPlace = selectedPlace {
            self.initialPlace = savedPlace
            self.displayCityId = savedPlace.cityRid
        }
    }
}
