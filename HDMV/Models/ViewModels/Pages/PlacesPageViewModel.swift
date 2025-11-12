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
    
    private var modelContext: ModelContext?
    private var placeSyncer: PlaceSyncer?
    
    @Published var isLoading = false
    @Published private var places: [Place] = []
    @Published var filteredPlaces: [Place] = []
    
    @Published var selectedCity: City? {
        didSet {
            updateFilteredPlaces()
        }
    }
    
    // MARK: Initialization
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.placeSyncer = PlaceSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let placeDescriptor = FetchDescriptor<Place>(sortBy: [SortDescriptor(\.name)])
            self.places = try context.fetch(placeDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = placeSyncer else {
            print("⚠️ [PlacesPageViewModel] Syncer is nil")
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
        guard let syncer = placeSyncer else {
            print("⚠️ [PlacesPageViewModel] countriesSyncer is nil")
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
    
    private func updateFilteredPlaces() {
        if let selectedCity = selectedCity {
            self.filteredPlaces = places.filter { $0.cityRid == selectedCity.rid }
        } else {
            self.filteredPlaces = places.filter { $0.cityRid == nil }
        }
    }
    
    // MARK: - User Actions
    
    func createPlace() {
        guard let context = modelContext else { return }
        let newPlace = Place(syncStatus: .local)
        newPlace.cityRid = selectedCity?.rid
        
        context.insert(newPlace)
        places.append(newPlace)
        filteredPlaces.append(newPlace)
        
        do {
            try context.save()
        } catch {
            print("Failed to create Place: \(error)")
        }
    }
    

    
}
