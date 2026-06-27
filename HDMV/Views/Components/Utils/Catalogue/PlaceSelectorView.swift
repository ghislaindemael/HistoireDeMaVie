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
    var selectedVehicle: Vehicle?
    var targetDate: Date?
    var disableSuggestion: Bool
    var isForTrip: Bool
    
    @State private var displayCityId: Int?
    @State private var initialPlace: Place?
    @State private var uncachedPlaceholder: Place?
    @State private var uncachedCity: City?
    @State private var showAllPlaces: Bool = false
    
    @State private var suggestedPlace: Place?
    @State private var showSuggestion: Bool = true
    @State private var hasComputedSuggestion: Bool = false
    
    // MARK: - Init
    
    init(selectedPlace: Binding<Place?>, linkedPlaceRid: Int? = nil, selectedVehicle: Vehicle? = nil, targetDate: Date? = nil, disableSuggestion: Bool = false, isForTrip: Bool = false) {
        self._selectedPlace = selectedPlace
        self.linkedPlaceRid = linkedPlaceRid
        self.selectedVehicle = selectedVehicle
        self.targetDate = targetDate
        self.disableSuggestion = disableSuggestion
        self.isForTrip = isForTrip
    }
    
    private func initializeState() {
        if let savedPlace = selectedPlace {
            self.initialPlace = savedPlace
            self.displayCityId = savedPlace.cityRid
            self.checkUncachedCity(cityRid: savedPlace.cityRid)
        } else if let rid = linkedPlaceRid {
            if let fetched = fetchPlace(withId: rid) {
                self.selectedPlace = fetched
                self.displayCityId = fetched.cityRid
                self.checkUncachedCity(cityRid: fetched.cityRid)
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
    
    @Query(FetchDescriptor<TransitLine>())
    private var transitLines: [TransitLine]
    
    private var placesForSelectedCity: [Place] {
        guard let cityId = displayCityId else { return [] }
        let predicate = #Predicate<Place> {
            $0.cityRid == cityId &&
            $0.cache == true
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Place.name)])
        let allPlacesInCity = (try? modelContext.fetch(descriptor)) ?? []
        
        return filterPlacesByVehicle(allPlacesInCity)
    }
    
    private func filterPlacesByVehicle(_ places: [Place]) -> [Place] {
        // Option check
        let filteredByOptions = places.filter { place in
            if isForTrip {
                if let options = place.decodedOptions, let reachable = options.reachableInTrip, reachable == false {
                    return false
                }
            }
            return true
        }
        
        guard !showAllPlaces else { return filteredByOptions }
        guard let vehicle = selectedVehicle else { return filteredByOptions }
        
        return filteredByOptions.filter { place in
            // Rule 1: Transit Line
            if let vRid = vehicle.rid {
                let matchingTransitLines = transitLines.filter { $0.allowedVehicleRids?.contains(vRid) == true }
                if !matchingTransitLines.isEmpty {
                    let allowedPlaceRids = matchingTransitLines.flatMap { $0.stops ?? [] }
                        .compactMap { $0.station?.placeRid }
                    if place.rid != nil && allowedPlaceRids.contains(place.rid!) {
                        return true
                    }
                }
            }
            
            // Rule 2, 3, 4: Generic Filtering
            let emptyIds = place.allowedVehicleRids.isEmpty
            let emptySlugs = place.allowedVehicleTypeSlugs.isEmpty
            
            // Rule 2: Both empty
            if emptyIds && emptySlugs { return true }
            
            // Rule 3: Specific ID
            if let vRid = vehicle.rid, place.allowedVehicleRids.contains(vRid) {
                return true
            }
            
            // Rule 4: Broad Type
            if place.allowedVehicleTypeSlugs.contains(vehicle.typeSlug) {
                return true
            }
            
            return false
        }
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
            
            if showSuggestion, let suggestion = suggestedPlace, suggestion.rid != selectedPlace?.rid {
                Divider()
                Button {
                    withAnimation {
                        displayCityId = suggestion.cityRid
                        selectedPlace = suggestion
                        showSuggestion = false
                    }
                } label: {
                    Label("\(suggestion.name)", systemImage: "sparkles")
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.borderless)
                .padding(.top, 4)
            }
        }
        .onAppear {
            initializeState()
            computeSuggestedPlace()
        }
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
            
            if let uncached = uncachedCity {
                Text("\(uncached.name) (Uncached)").tag(uncached.rid as Int?)
            }
            
            ForEach(cities) { city in
                Text(city.name).tag(city.rid as Int?)
            }
        }
        .onChange(of: displayCityId) { oldId, newId in
            if oldId != nil && oldId != newId {
                selectedPlace = nil
            }
        }
    }
    
    private var placePicker: some View {
        Picker("Place", selection: $selectedPlace) {
            Text("Select a Place").tag(nil as Place?)
            
            if let selected = selectedPlace, !placesForSelectedCity.contains(where: { $0.id == selected.id }) {
                if selected.cityRid == displayCityId {
                    Text("\(selected.name) (Uncached)").tag(selected as Place?)
                }
            }
            
            let favorites = placesForSelectedCity.filter { $0.isFavorite }
            let others = placesForSelectedCity.filter { !$0.isFavorite }
            
            if !favorites.isEmpty {
                ForEach(favorites) { place in
                    Text(place.name).tag(place as Place?)
                }
                Divider()
            }
            
            ForEach(others) { place in
                Text(place.name).tag(place as Place?)
            }
            
            if selectedVehicle != nil {
                Divider()
                Toggle("Show all places", isOn: $showAllPlaces)
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
    
    private func checkUncachedCity(cityRid: Int?) {
        guard let cityRid = cityRid else { return }
        if !cities.contains(where: { $0.rid == cityRid }) {
            self.uncachedCity = fetchCity(withId: cityRid)
        }
    }
    
    private func fetchCity(withId id: Int?) -> City? {
        guard let cityId = id else { return nil }
        let predicate = #Predicate<City> { $0.rid == cityId }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    private func computeSuggestedPlace() {
        guard !hasComputedSuggestion, !disableSuggestion else { return }
        hasComputedSuggestion = true
        
        let date = targetDate ?? .now
        
        // 1. Fetch latest Trip end place
        let tripsPredicate = #Predicate<Trip> { $0.timeStart <= date }
        var tripsDescriptor = FetchDescriptor(predicate: tripsPredicate, sortBy: [SortDescriptor(\.timeStart, order: .reverse)])
        tripsDescriptor.fetchLimit = 30
        let recentTrips = (try? modelContext.fetch(tripsDescriptor)) ?? []
        
        var latestTrip: Trip? = nil
        for trip in recentTrips {
            if let end = trip.timeEnd, end <= date, trip.placeEndRid != nil {
                latestTrip = trip
                break
            }
        }
        
        // 2. Fetch latest Activity with a Place
        let activitiesPredicate = #Predicate<ActivityInstance> { $0.timeStart <= date }
        var activitiesDescriptor = FetchDescriptor(predicate: activitiesPredicate, sortBy: [SortDescriptor(\.timeStart, order: .reverse)])
        activitiesDescriptor.fetchLimit = 30 // Check up to 30 recent activities
        let recentActivities = (try? modelContext.fetch(activitiesDescriptor)) ?? []
        
        var latestActivityWithPlace: ActivityInstance? = nil
        for activity in recentActivities {
            if activity.decodedActivityDetails?.place?.placeId != nil {
                latestActivityWithPlace = activity
                break
            }
        }
        
        let tripTime = latestTrip?.timeEnd ?? .distantPast
        let activityTime = latestActivityWithPlace?.timeStart ?? .distantPast
        
        if tripTime == .distantPast && activityTime == .distantPast {
            return
        }
        
        if activityTime >= tripTime {
            if let placeId = latestActivityWithPlace?.decodedActivityDetails?.place?.placeId {
                self.suggestedPlace = fetchPlace(withId: placeId)
            }
        } else {
            self.suggestedPlace = latestTrip?.placeEnd
        }
    }
    
}
