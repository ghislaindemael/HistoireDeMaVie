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
    
    private var modelContext: ModelContext?
    private var settings = SettingsStore.shared
    @Published var isLoading = false
        
    private let citiesService = CitiesService()
    @Published var cities: [City] = []
    @Published var countries: [Country] = []
    @Published var filteredCities: [City] = []

    
    @Published var selectedCountry: Country? {
        didSet {
            updateFilteredCities()
        }
    }
    
    
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
    
    // This private function updates the filtered list whenever the source data changes
    private func updateFilteredCities() {
        guard let selectedCountry else {
            self.filteredCities = []
            return
        }
        self.filteredCities = cities.filter { $0.country_id == selectedCountry.id }
    }
    
    
    func refreshDataFromServer() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            
            let dtos = try await citiesService.fetchCities(
                includeArchived: settings.includeArchived
            )

            var masterList: [City] = []
            for dto in dtos {
                masterList.append(
                    City(fromDto: dto)
                )
            }
                    
            masterList.sort { c1, c2 in
                 return c1.name < c2.name
            }
            self.cities = masterList
            updateFilteredCities()
            
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func cacheCities() {
        guard let context = modelContext, let selectedCountry = selectedCountry else {
            print("Cannot cache: model context or selected country is missing.")
            return
        }
        
        print("Caching cities for \(selectedCountry.name)...")
        
        do {
            let countryId = selectedCountry.id
            let predicate = #Predicate<City> { city in
                city.country_id == countryId
            }
            let descriptor = FetchDescriptor<City>(predicate: predicate)
            let existingCities = try context.fetch(descriptor)
            
            for city in existingCities {
                context.delete(city)
            }
            print("Deleted \(existingCities.count) existing cached cities for this country.")
            
            let citiesToCache = self.cities.filter { $0.country_id == countryId && $0.cache }
            
            for city in citiesToCache {
                context.insert(city)
            }
            print("Inserting \(citiesToCache.count) new cities to cache.")
            
            try context.save()
            print("Successfully cached cities for \(selectedCountry.name).")
            
        } catch {
            print("Failed to perform targeted cache for cities: \(error)")
        }
    }
    
    
    
    // MARK: - User Actions
    
    func createCity(name: String, slug: String, country: Country, rank: Int) async {
        guard let context = modelContext else { return }
        let payload = NewCityPayload(slug: slug, name: name, rank: rank, country_id: country.id)
        
        do {
            let newCityDTO = try await citiesService.createCity(payload)
            let newCity = City(fromDto: newCityDTO)
            context.insert(newCity)
            try? context.save()
            fetchFromCache()
        } catch {
            print("Failed to create city: \(error)")
        }
    }
    
    func updateRank(for city: City, to newRank: Int) {
        guard let context = modelContext else { return }
        let oldRank = city.rank

        city.rank = newRank
        
        Task {
            do {
                try await citiesService.updateRank(forCityId: city.id, newRank: newRank)
                try context.save()
                
            } catch {
                print("Failed to update rank on server: \(error). Reverting.")
                city.rank = oldRank
                cities.sort { c1, c2 in
                    return c1.name < c2.name
                }
            }
        }
    }
    
    /// Toggles the cache status for a city.
    func toggleCache(for city: City) {
        Task {
            do {
                try await citiesService.updateCacheStatus(
                    forCityId: city.id, shouldCache: city.cache
                )
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
    
    func unarchiveCity(for city: City) {
        city.archived = false
        
        Task {
            do {
                try await citiesService.unarchiveCity(id: city.id)
                objectWillChange.send()
            } catch {
                print("Failed to un-archive city on server: \(error). Reverting.")
                city.archived = true
                objectWillChange.send()
            }
        }
    }

    
}
