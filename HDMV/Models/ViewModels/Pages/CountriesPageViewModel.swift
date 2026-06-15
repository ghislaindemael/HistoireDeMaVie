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
    private var countriesSyncer: CountrySyncer?

    @Published var isLoading = false
    @Published var countries: [Country] = []
    
    
    // MARK: Initialization
            
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.countriesSyncer = CountrySyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    func fetchFromCache() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
        do {
            self.countries = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch countries: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = countriesSyncer else {
            print("⚠️ [CountriesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            try await syncer.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func fetchArchivedFromServer() async {
        SettingsStore.shared.includeArchived = true
        defer { SettingsStore.shared.includeArchived = false }
        
        await refreshFromServer()
    }
    
    func purgeArchivedFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let predicate = #Predicate<Country> { $0.archived == true }
            let descriptor = FetchDescriptor<Country>(predicate: predicate)
            let archivedItems = try context.fetch(descriptor)
            
            for item in archivedItems {
                context.delete(item)
            }
            try? context.save()
            fetchFromCache()
        } catch {
            print("Failed to purge archived countries: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = countriesSyncer else {
            print("⚠️ [CountriesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            // TODO: For cleancode, add City update for first country sync
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    // MARK: - User Actions
            
    func createCountry() {
        guard let context = modelContext else { return }
        let newCountry = Country(syncStatus: .unsynced)
        context.insert(newCountry)
        do {
            try context.save()
        } catch {
            print("Failed to create country: \(error)")
        }
    }
        
    func updateModel(_ model: Country, modifier: (Country) -> Void) {
        modifier(model)
        try? modelContext?.save()
    }
    
    func deleteCountries(at offsets: IndexSet) {
        guard let context = modelContext else { return }
        for index in offsets {
            let country = countries[index]
            context.delete(country)
        }
        try? context.save()
        fetchFromCache()
    }
    
    

    
    
}

