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
    private var settings: SettingsStore?
    
    
    @Published var isLoading = false
    @Published var countries: [Country] = []
    
    private let countriesService = CountriesService()
    
    // MARK: Initialization
    
    init() {}
        
    func setup(modelContext: ModelContext, settings: SettingsStore) {
        self.modelContext = modelContext
        self.settings = settings
        
        fetchFromCache()
        
        if countries.isEmpty {
            Task {
                await fetchFromServer()
            }
        }
    }
    
    
    // MARK: - Data Loading and Caching
    
    func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
            self.countries = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func fetchFromServer() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dtos = try await countriesService.fetchCountries()
            
            countries = dtos
                .map(Country.init(fromDto:))
                .sorted { $0.name < $1.name }
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
    
    func createCountry(payload: NewCountryPayload) async {
        guard let context = modelContext else { return }
        
        do {
            let newCountryDTO = try await countriesService.createCountry(payload: payload)
            let newCountry = Country(fromDto: newCountryDTO)
            context.insert(newCountry)
            try? context.save()
            fetchFromCache()
        } catch {
            print("Failed to create city: \(error)")
        }
    }
        
    /// Toggles the cache status for a country.
    func updateCache(for country: Country) {
        Task {
            do {
                try await countriesService.updateCacheStatus(for: country)
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
                try await countriesService.archiveCountry(country: country)
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
                try await countriesService.unarchiveCountry(country: country)
                objectWillChange.send()
            } catch {
                print("Failed to un-archive country: \(error). Reverting.")
                country.archived = true
                objectWillChange.send()
            }
        }
    }
    
    
}

extension CountriesPageViewModel: CountriesPageViewModelProtocol {}
