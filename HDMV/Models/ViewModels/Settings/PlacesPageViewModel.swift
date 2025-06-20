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
    // We also need the CitiesService to get the list of cities for filtering
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

        do {
            async let placeDTOs = try placesService.fetchPlaces()
            async let cityDTOs = try citiesService.fetchCities()
            
            // Clear old cache
            try context.delete(model: Place.self)
            try context.delete(model: City.self) // Also refresh cities
            
            // Insert new data
            for dto in try await cityDTOs {
                if let id = dto.id {
                    context.insert(City(id: id, slug: dto.slug, name: dto.name, rank: dto.rank, country_id: dto.country_id))
                }
            }
            for dto in try await placeDTOs {
                if let id = dto.id {
                    context.insert(Place(id: id, name: dto.name, city_id: dto.city_id))
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
        let payload = NewPlacePayload(name: name, city_id: city.id)
        
        do {
            let createdDTO = try await placesService.createPlace(payload)
            guard let finalId = createdDTO.id else { return }
            
            let finalPlace = Place(id: finalId, name: createdDTO.name, city_id: createdDTO.city_id)
            context.insert(finalPlace)
            try context.save()
            
            fetchFromCache()
        } catch {
            print("Failed to create place: \(error)")
        }
    }
}
