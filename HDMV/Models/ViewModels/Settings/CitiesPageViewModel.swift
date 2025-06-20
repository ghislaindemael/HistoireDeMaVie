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
    
    private var modelContext: ModelContext?
    private let citiesService = CitiesService()

    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchFromCache()
        
        if cities.isEmpty || countries.isEmpty {
            Task {
                await refreshDataFromServer()
            }
        }
    }
    
    // MARK: - Data Loading and Caching
    
    func refreshDataFromServer() async {
        guard let context = modelContext else { return }
        
        do {
            async let cityDTOs = try citiesService.fetchCities()
            async let countryDTOs = try citiesService.fetchCountries()
            
            try context.delete(model: City.self)
            try context.delete(model: Country.self)
            
            for dto in try await countryDTOs {
                context.insert(Country(id: dto.id, slug: dto.slug, name: dto.name))
            }
            for dto in try await cityDTOs {
                if let id = dto.id {
                    context.insert(City(id: id, slug: dto.slug, name: dto.name, rank: dto.rank, country_id: dto.country_id))
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
            let cityDescriptor = FetchDescriptor<City>(sortBy: [
                SortDescriptor(\.rank),
                SortDescriptor(\.name)
            ])
            self.cities = try context.fetch(cityDescriptor)
                        
            let countryDescriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
            self.countries = try context.fetch(countryDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    // MARK: - User Actions
    
    func createCity(name: String, slug: String, country: Country, rank: Int) async {
        guard let context = modelContext else { return }
        let payload = NewCityPayload(slug: slug, name: name, rank: rank, country_id: country.id)
        
        do {
            let createdDTO = try await citiesService.createCity(payload)
            guard let finalId = createdDTO.id else { return }
            
            let finalCity = City(id: finalId, slug: createdDTO.slug, name: createdDTO.name, rank: createdDTO.rank, country_id: createdDTO.country_id)
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
            let cityDTO = CityDTO(id: city.id, slug: city.slug, name: city.name, rank: newRank, country_id: city.country_id)
            do {
                try await citiesService.updateCity(cityDTO)
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
}
