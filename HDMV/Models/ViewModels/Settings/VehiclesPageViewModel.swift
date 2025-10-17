//
//  PlacesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//

import Foundation
import SwiftData

@MainActor
class VehiclesPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private var vehicleSyncer: VehicleSyncer?
    
    @Published var isLoading = false
    @Published private var vehicles: [Vehicle] = []
    @Published var filteredVehicles: [Vehicle] = []
    
    @Published var selectedType: VehicleType? {
        didSet {
            updateFilteredVehicles()
        }
    }
    
    // MARK: Initialization
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.vehicleSyncer = VehicleSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Vehicle>(sortBy: [SortDescriptor(\.name)])
            self.vehicles = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = vehicleSyncer else {
            print("⚠️ [VehiclesPageViewModel] Syncer is nil")
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
        guard let syncer = vehicleSyncer else {
            print("⚠️ [VehiclesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            // TODO: For cleancode, add Trip Leg update on Vehicle Sync
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    private func updateFilteredVehicles() {
        if let selectedType = selectedType {
            self.filteredVehicles = vehicles.filter { $0.type == selectedType }
        } else {
            self.filteredVehicles = vehicles
        }
    }
    
    // MARK: - User Actions
    
    func createVehicle() {
        guard let context = modelContext else { return }
        let newVehicle = Vehicle(type: selectedType, syncStatus: .local)
        context.insert(newVehicle)
        vehicles.append(newVehicle)
        filteredVehicles.append(newVehicle)
        
        do {
            try context.save()
        } catch {
            print("Failed to create Vehicle: \(error)")
        }
    }
    

    
}
