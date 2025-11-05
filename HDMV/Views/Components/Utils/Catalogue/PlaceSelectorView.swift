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
    var linkedPlaceRid: Int?
    
    @State private var displayCityId: Int?
    @State private var initialPlace: Place?
    @State private var uncachedPlaceholder: Place?
    
    // MARK: - Init
    
    init(selectedPlace: Binding<Place?>, linkedPlaceRid: Int? = nil) {
        self._selectedPlace = selectedPlace
        self.linkedPlaceRid = linkedPlaceRid
    }
    
    private func initializeState() {
        if let savedPlace = selectedPlace {
            self.initialPlace = savedPlace
            self.displayCityId = savedPlace.cityRid
        } else if let rid = linkedPlaceRid {
            if let fetched = fetchPlace(withId: rid) {
                self.selectedPlace = fetched
                self.displayCityId = fetched.cityRid
            } else {
                self.uncachedPlaceholder = Place(rid: rid, name: "Uncached Place")
            }
        }
    }
    
    // MARK: - Data Queries
    @Query(FetchDescriptor<City>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.name)]))
    private var cities: [City]
    
    private var placesForSelectedCity: [Place] {
        guard let cityId = displayCityId else { return [] }
        let predicate = #Predicate<Place> {
            $0.cityRid == cityId &&
            $0.cache == true
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Place.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading) {
            if let uncached = uncachedPlaceholder {
                HStack {
                    Text("Uncached place:")
                    Spacer()
                    Text("Rid: #\(uncached.rid ?? -1)")
                        .foregroundStyle(.orange)
                        .bold()
                }
                Divider()
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
                Text(place.name).tag(place as Place?)
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
    
    
}
