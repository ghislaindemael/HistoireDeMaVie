//
//  PlaceDetailsEditView.swift
//  HDMV
//
//  Created by Ghislain Demael on 02.09.2025.
//

import SwiftUI

struct PlaceDetailsEditView: View {
    @Binding var metadata: ActivityDetails?
    let activityType: ActivityType
    let cities: [City]
    let places: [Place]
    
    /// This state variable controls which city's places are *displayed* in the picker.
    /// It allows the user to browse cities without changing the saved data.
    @State private var displayCityId: Int?
    
    /// This is a safe binding directly to the place ID in your data model.
    /// Its 'setter' ensures the necessary data objects are created before saving.
    private var placeIdBinding: Binding<Int?> {
        Binding<Int?>(
            get: { metadata?.place?.placeId },
            set: { newPlaceId in
                if metadata == nil {
                    metadata = ActivityDetails()
                }
                if metadata?.place == nil {
                    metadata?.place = PlaceDetails()
                }
                metadata?.place?.placeId = newPlaceId
                
                if let place = resolvePlace(newPlaceId) {
                    displayCityId = place.city_id
                }
            }
        )
    }
    
    /// A computed property that returns a clear summary of the current selection.
    private var selectionSummary: String {
        guard let placeId = metadata?.place?.placeId,
              let place = resolvePlace(placeId) else {
            return "Not Selected"
        }
        
        let cityName = cities.first(where: { $0.id == place.city_id })?.name ?? place.city_name
        
        return "\(cityName) – \(place.name)"
    }
    
    var body: some View {
        Section() {
            HStack {
                Text("Selected")
                Spacer()
                Text(selectionSummary)
            }
            
            Picker("City", selection: $displayCityId) {
                Text("Select a City").tag(nil as Int?)
                ForEach(cities) { city in
                    Text(city.name).tag(city.id as Int?)
                }
                
                if let savedPlace = resolvePlace(metadata?.place?.placeId),
                   !cities.contains(where: { $0.id == savedPlace.city_id }) {
                    Text(savedPlace.city_name.isEmpty ? "Archived City" : savedPlace.city_name)
                        .foregroundStyle(.secondary)
                        .tag(savedPlace.city_id as Int?)
                }
            }
            
            if let cityId = displayCityId {
                Picker("Place", selection: placeIdBinding) {
                    Text("Select a Place").tag(nil as Int?)
                    ForEach(places.filter { $0.city_id == cityId }) { place in
                        Text(place.name).tag(place.id as Int?)
                    }
                    
                    if let savedPlace = resolvePlace(metadata?.place?.placeId),
                       savedPlace.city_id == cityId,
                       !places.contains(where: { $0.id == savedPlace.id }) {
                        Text(savedPlace.name)
                            .foregroundStyle(.secondary)
                            .tag(savedPlace.id as Int?)
                    }
                }
            }
        }
        .onAppear(perform: initializeDisplayCity)
    }
    
    /// Finds a place by its ID, returning a temporary "Archived" version if not found.
    private func resolvePlace(_ placeId: Int?) -> Place? {
        guard let id = placeId else { return nil }
        return places.first(where: { $0.id == id })
    }
    
    /// Sets the initial state of the City picker when the view appears.
    private func initializeDisplayCity() {
        if let place = resolvePlace(metadata?.place?.placeId) {
            displayCityId = place.city_id
        }
    }
}
