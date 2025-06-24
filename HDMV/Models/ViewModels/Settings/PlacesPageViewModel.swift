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
    @Published var places: [Place] = []
    @Published var cities: [City] = []
    @Published var isLoading = false
    
    private let placesService = PlacesService()
    private let citiesService = CitiesService()
    
    private var modelContext: ModelContext?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchFromCache()
        
        if cities.isEmpty {
            Task { await refreshDataFromServer() }
        }
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let placeDescriptor = FetchDescriptor<Place>(sortBy: [SortDescriptor(\.name)])
            self.places = try context.fetch(placeDescriptor)
            
            let cityDescriptor = FetchDescriptor<City>(
                predicate: #Predicate { $0.cache == true },
                sortBy: [SortDescriptor(\.rank), SortDescriptor(\.name)]
            )
            self.cities = try context.fetch(cityDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshDataFromServer() async {
        guard let context = modelContext else { return }
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            // Fetch places from network (both cachable and uncachable)
            async let cachablePlacesDTOs = try placesService.fetchCachablePlaces()
            async let uncachablePlacesDTOs = try placesService.fetchUncachablePlaces()
            
            let cachablePlaces = try await cachablePlacesDTOs
            let uncachablePlaces = try await uncachablePlacesDTOs
            
            // Fetch cities only from local cache
            let cityDescriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.rank), SortDescriptor(\.name)])
            let cachedCities = try context.fetch(cityDescriptor)
            let cityMap = Dictionary(uniqueKeysWithValues: cachedCities.map { ($0.id, $0.name) })
            
            // Combine places for UI display (master list)
            let allPlacesDTOs = cachablePlaces + uncachablePlaces
            self.places = allPlacesDTOs.compactMap { dto in
                guard let id = dto.id else { return nil }
                let place = Place(id: id, name: dto.name, city_id: dto.city_id, cache: dto.cache)
                place.localName = "\(cityMap[dto.city_id] ?? "Unknown City") - \(place.name)"
                return place
            }.sorted { $0.name < $1.name }
            
            // Cache only cachable places (clear old cached places first)
            try context.delete(model: Place.self)
            for dto in cachablePlaces where dto.cache == true {
                guard let id = dto.id else { continue }
                let place = Place(id: id, name: dto.name, city_id: dto.city_id, cache: true)
                place.localName = "\(cityMap[dto.city_id] ?? "Unknown City") - \(place.name)"
                context.insert(place)
            }
            
            try context.save()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }


    
    // MARK: - User Actions
    
    func createPlace(name: String, city: City) async {
        guard let context = modelContext else { return }
        let payload = NewPlacePayload(name: name, city_id: city.id, cache: true)
        
        do {
            let createdDTO = try await placesService.createPlace(payload)
            guard let finalId = createdDTO.id else { return }
            
            let finalPlace = Place(id: finalId, name: createdDTO.name, city_id: createdDTO.city_id, cache: createdDTO.cache)
            finalPlace.localName = "\(city.name) - \(finalPlace.name)"
            context.insert(finalPlace)
            try context.save()
            
            fetchFromCache()
        } catch {
            print("Failed to create place: \(error)")
        }
    }
    
    /// Toggles the cache status for a place.
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
    
    /// Archives a place instead of deleting it.
    func archivePlace(for place: Place) {
        guard let context = modelContext else { return }
        
        places.removeAll { $0.id == place.id }
        
        Task {
            do {
                try await placesService.archivePlace(forPlaceId: place.id)
                context.delete(place)
                try context.save()
            } catch {
                print("Failed to archive place on server: \(error).")
                fetchFromCache()
            }
        }
    }
}
