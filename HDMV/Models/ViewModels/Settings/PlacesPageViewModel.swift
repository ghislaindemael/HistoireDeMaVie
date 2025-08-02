//
//  PlacesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//

import Foundation
import SwiftData

@MainActor
class PlacesPageViewModel: ObservableObject {

    @Published private var places: [Place] = []
    
    @Published var cities: [City] = []
    @Published var filteredPlaces: [Place] = []
    @Published var isLoading = false
    
    @Published var selectedCity: City? {
        didSet {
            updateFilteredPlaces()
        }
    }
    
    private let placesService = PlacesService()
    private var modelContext: ModelContext?
    private var settings = SettingsStore.shared
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchFromCache()
        
        if cities.isEmpty {
            Task { await refreshDataFromServer() }
        }
    }
    
    // MARK: - Data Filtering
    
    /// Updates the published `filteredPlaces` array based on the `selectedCity`.
    private func updateFilteredPlaces() {
        guard let selectedCity else {
            self.filteredPlaces = []
            return
        }
        self.filteredPlaces = places.filter { $0.city_id == selectedCity.id }
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let placeDescriptor = FetchDescriptor<Place>(sortBy: [SortDescriptor(\.name)])
            self.places = try context.fetch(placeDescriptor)
            
            let cityDescriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.rank), SortDescriptor(\.name)])
            self.cities = try context.fetch(cityDescriptor)
            
            updateFilteredPlaces()
            
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    /// Refreshes the master list of places of city from the server. Caching is now a separate step.
    func refreshDataFromServer() async {
        guard let selectedCity else { return }
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let allPlacesDTOs = try await placesService.fetchPlaces(
                forCityId: selectedCity.id,
                includeArchived: settings.includeArchived
            )
            
            self.places = allPlacesDTOs.compactMap { Place(fromDto: $0) }
            updateFilteredPlaces()
            
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    /// Caches only the places for the currently selected city.
    func cachePlacesForSelectedCity() {
        guard let context = modelContext, let selectedCity = selectedCity else {
            print("Cannot cache: model context or selected city is missing.")
            return
        }
        
        print("Caching places for \(selectedCity.name)...")
        
        do {
            let cityId = selectedCity.id
            let cityName = selectedCity.name
            let predicate = #Predicate<Place> { $0.city_id == cityId }
            let descriptor = FetchDescriptor<Place>(predicate: predicate)
            let existingPlaces = try context.fetch(descriptor)
            
            for place in existingPlaces {
                context.delete(place)
            }
            
            let placesToCache = self.places.filter { $0.city_id == cityId && $0.cache }
            
            for place in placesToCache {
                place.city_name = cityName
                context.insert(place)
            }
            
            try context.save()
            print("Successfully cached places for \(selectedCity.name).")
            
        } catch {
            print("Failed to perform targeted cache for places: \(error)")
        }
    }
    
    
    func createPlace(name: String, city: City) async {
        let payload = NewPlacePayload(name: name, city_id: city.id)
        do {
            _ = try await placesService.createPlace(payload)
            await refreshDataFromServer()
        } catch {
            print("Failed to create place: \(error)")
        }
    }
    
    func toggleCache(for place: Place) {
        Task {
            do {
                try await placesService.updateCacheStatus(forPlaceId: place.id, isActive: place.cache)
                try modelContext?.save()
            } catch {
                print("Failed to update place cache status: \(error). Reverting.")
                place.cache.toggle()
            }
        }
    }
    
    func archivePlace(for place: Place) {
        Task {
            do {
                try await placesService.archivePlace(forPlaceId: place.id)
                await refreshDataFromServer()
            } catch {
                print("Failed to archive place on server: \(error).")
            }
        }
    }
    
    func unarchivePlace(for place: Place) {
        Task {
            do {
                try await placesService.unarchivePlace(forPlaceId: place.id)
                await refreshDataFromServer()
            } catch {
                print("Failed to archive place on server: \(error).")
            }
        }
    }
}
