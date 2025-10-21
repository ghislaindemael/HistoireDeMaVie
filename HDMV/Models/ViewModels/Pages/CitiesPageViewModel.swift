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
    private var citySyncer: CitySyncer?
    
    @Published var isLoading = false
    @Published var cities: [City] = []
    @Published var filteredCities: [City] = []

    @Published var selectedCountry: Country? {
        didSet {
            updateFilteredCities()
        }
    }
    
    // MARK: Initialization
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.citySyncer = CitySyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let cityDescriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.name)])
            self.cities = try context.fetch(cityDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = citySyncer else {
            print("⚠️ [CitiesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            try await syncer.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = citySyncer else {
            print("⚠️ [CitiesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            // TODO: For cleancode, add Place update on City Sync
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    private func updateFilteredCities() {
        if let selectedCountry = selectedCountry {
            self.filteredCities = cities.filter { $0.countryRid == selectedCountry.rid }
        } else {
            self.filteredCities = cities.filter { $0.countryRid == nil }
        }
    }
    
    
    // MARK: - User Actions
        
    func createCity() {
        guard let context = modelContext else { return }
        
        let newCity = City(
            slug:"unset",
            name: "Unset",
            syncStatus: .local
        )
        newCity.relCountry = selectedCountry
        
        context.insert(newCity)
        cities.append(newCity)
        filteredCities.append(newCity)
        
        do {
            try context.save()
        } catch {
            print("Failed to create city: \(error)")
        }
    }
    
    
}
