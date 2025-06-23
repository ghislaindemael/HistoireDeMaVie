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
    
    func refreshDataFromServer() async {
        guard let context = modelContext else { return }
        self.isLoading = true
        defer { self.isLoading = false }
        
        self.cities = []
        self.places = []

        do {
            async let placeDTOs = try placesService.fetchPlaces()
            async let cityDTOs = try citiesService.fetchCities()
            
            let fetchedCityDTOs = try await cityDTOs
            let fetchedPlaceDTOs = try await placeDTOs
            
            let cityIdToNameMap = fetchedCityDTOs.reduce(into: [Int: String]()) { dictionary, cityDTO in
                if let id = cityDTO.id {
                    dictionary[id] = cityDTO.name
                }
            }
            
            try context.delete(model: Place.self)
            try context.delete(model: City.self)
            
            for dto in fetchedCityDTOs {
                if let id = dto.id {
                    context.insert(City(id: id, slug: dto.slug, name: dto.name, rank: dto.rank, country_id: dto.country_id))
                }
            }
            for dto in fetchedPlaceDTOs {
                if let id = dto.id, dto.cache == true {
                    let newPlace = Place(id: id, name: dto.name, city_id: dto.city_id, cache: dto.cache)
                    let cityName = cityIdToNameMap[dto.city_id] ?? "Unknown City"
                    newPlace.localName = "\(cityName) - \(newPlace.name)"
                    context.insert(newPlace)
                }
            }
            
            try context.save()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let placeDescriptor = FetchDescriptor<Place>(sortBy: [SortDescriptor(\.name)])
            self.places = try context.fetch(placeDescriptor)
            
            let cityDescriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.rank), SortDescriptor(\.name)])
            self.cities = try context.fetch(cityDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
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
