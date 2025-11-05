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
    @Published var selectedCountry: Country?
    
    // MARK: Initialization
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.citySyncer = CitySyncer(modelContext: modelContext)
    }
    
    // MARK: - Data Loading and Caching
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = citySyncer else {
            print("⚠️ [CitiesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            try await syncer.pullChanges()
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
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    // MARK: - User Actions
        
    func createCity() {
        
        guard let context = modelContext else { return }

        let existing = try? context.fetch(FetchDescriptor<City>(
            predicate: #Predicate { $0.slug == "unset" || $0.name == "Unset"}
        )).first
        
        if existing != nil {
            return
        }

        
        let newCity = City()
        newCity.setCountry(selectedCountry)
        context.insert(newCity)
        
        do {
            try context.save()
            print("✅ Created new placeholder city.")
        } catch {
            context.rollback()
            print("❌ Failed to create city: \(error)")
        }
    }

    
    
}
