//
//  CountriesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import Foundation
import SwiftData

@MainActor
class CountriesPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private var settings = SettingsStore.shared
    @Published var isLoading = false
    
    private let countriesService = CountriesService()
    @Published var countries: [Country] = []
        
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchFromCache()
        if countries.isEmpty {
            Task {
                await refreshDataFromServer()
            }
        }
    }
    
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
            self.countries = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshDataFromServer() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            
            let dtos = try await countriesService.fetchCountries(
                includeArchived: settings.includeArchived
            )
            
            var masterList: [Country] = []
            for dto in dtos {
                masterList.append(
                    Country(fromDto: dto)
                )
            }
            
            masterList.sort { c1, c2 in
                return c1.name < c2.name
            }
            self.countries = masterList
            
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func cacheCountries() {
        guard let context = modelContext else {
            print("Cannot cache: model context is missing.")
            return
        }
                
        do {
            try context.delete(model: Country.self)
            let countriesToCache = self.countries.filter { $0.cache }
            
            for country in countriesToCache {
                context.insert(country)
            }
            try context.save()
        } catch {
            print("Failed to perform targeted cache for countries: \(error)")
        }
    }
    
    
    // MARK: - User Actions
    
    func createCountry(name: String, slug: String) async {
        guard let context = modelContext else { return }
        let payload = NewCountryPayload(slug: slug, name: name)
        
        do {
            let newCountryDTO = try await countriesService.createCountry(payload)
            let newCountry = Country(fromDto: newCountryDTO)
            context.insert(newCountry)
            try? context.save()
            fetchFromCache()
        } catch {
            print("Failed to create city: \(error)")
        }
    }
        
    /// Toggles the cache status for a country.
    func toggleCache(for country: Country) {
        Task {
            do {
                try await countriesService.updateCacheStatus(
                    forCountryId: country.id, shouldCache: country.cache
                )
            } catch {
                print("Failed to update cache status on server: \(error). Reverting.")
                country.cache.toggle()
            }
        }
    }
    
    func archiveCountry(for country: Country) {
        guard let context = modelContext else { return }
                
        Task {
            do {
                try await countriesService.archiveCountry(id: country.id)
                context.delete(country)
                countries.removeAll { $0.id == country.id }

                try context.save()
            } catch {
                print("Failed to archive country: \(error).")
                fetchFromCache()
            }
        }
    }
    
    func unarchiveCountry(for country: Country) {
        country.archived = false
        
        Task {
            do {
                try await countriesService.unarchiveCountry(id: country.id)
                objectWillChange.send()
            } catch {
                print("Failed to un-archive country: \(error). Reverting.")
                country.archived = true
                objectWillChange.send()
            }
        }
    }
    
    
}
