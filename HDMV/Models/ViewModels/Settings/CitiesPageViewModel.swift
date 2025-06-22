//
//  CitiesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation
import SwiftData

@MainActor
class CitiesPageViewModel: ObservableObject {
        
    @Published var cities: [City] = []
    @Published var countries: [Country] = []
    @Published var isLoading = false
    
    
    private var modelContext: ModelContext?
    private let citiesService = CitiesService()
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchFromCache()
        if cities.isEmpty {
            Task {
                await refreshDataFromServer()
            }
        }
    }
    
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let cityDescriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.rank), SortDescriptor(\.name)])
            self.cities = try context.fetch(cityDescriptor)
            
            let countryDescriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
            self.countries = try context.fetch(countryDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    
    func refreshDataFromServer() async {
        guard let context = modelContext else { return }
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            async let cachedCityDTOs = try citiesService.fetchCachableCities()
            async let uncachedCityDTOs = try citiesService.fetchUncachableCities()
            
            let allDTOs = (try await cachedCityDTOs) + (try await uncachedCityDTOs)
            
            var masterList: [City] = []
            for dto in allDTOs {
                if let id = dto.id {
                    masterList.append(City(id: id, slug: dto.slug, name: dto.name, rank: dto.rank, country_id: dto.country_id, cache: dto.cache))
                }
            }
            masterList.sort { c1, c2 in
                if c1.rank != c2.rank { return c1.rank < c2.rank }
                else { return c1.name < c2.name }
            }
            self.cities = masterList
            
            try context.delete(model: City.self)
            
            for dto in try await cachedCityDTOs {
                if let id = dto.id {
                    context.insert(City(id: id, slug: dto.slug, name: dto.name, rank: dto.rank, country_id: dto.country_id, cache: dto.cache))
                }
            }
            
            try context.save()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    
    
    // MARK: - User Actions
    
    func createCity(name: String, slug: String, country: Country, rank: Int) async {
        guard let context = modelContext else { return }
        let payload = NewCityPayload(slug: slug, name: name, rank: rank, country_id: country.id)
        
        do {
            let createdDTO = try await citiesService.createCity(payload)
            guard let finalId = createdDTO.id else { return }
            
            let finalCity = City(id: finalId, slug: createdDTO.slug, name: createdDTO.name, rank: createdDTO.rank, country_id: createdDTO.country_id, cache: createdDTO.cache)
            context.insert(finalCity)
            try context.save()
            
            fetchFromCache()
        } catch {
            print("Failed to create city: \(error)")
        }
    }
    
    func updateRank(for city: City, to newRank: Int) {
        guard let context = modelContext else { return }
        let oldRank = city.rank

        city.rank = newRank
        cities.sort { c1, c2 in
            if c1.rank != c2.rank {
                return c1.rank < c2.rank
            } else {
                return c1.name < c2.name
            }
        }
        
        Task {
            do {
                try await citiesService.updateRank(forCityId: city.id, newRank: newRank)
                try context.save()
                
            } catch {
                print("Failed to update rank on server: \(error). Reverting.")
                city.rank = oldRank
                cities.sort { c1, c2 in
                    if c1.rank != c2.rank {
                        return c1.rank < c2.rank
                    } else {
                        return c1.name < c2.name
                    }
                }
            }
        }
    }
    
    /// Toggles the cache status for a city.
    func toggleCache(for city: City) {
        guard let context = modelContext else { return }
        
        Task {
            do {
                try await citiesService.updateCacheStatus(forCityId: city.id, isActive: city.cache)
                if city.cache {
                    context.insert(city)
                } else {
                    context.delete(city)
                }
                try context.save()
                
            } catch {
                print("Failed to update cache status on server: \(error). Reverting.")
                city.cache.toggle()
            }
        }
    }
    
    func archiveCity(for city: City) {
        guard let context = modelContext else { return }
        
        cities.removeAll { $0.id == city.id }
        
        Task {
            do {
                try await citiesService.archiveCity(id: city.id)
                context.delete(city)
                try context.save()
            } catch {
                print("Failed to archive city on server: \(error).")
                fetchFromCache()
            }
        }
    }
    
}
