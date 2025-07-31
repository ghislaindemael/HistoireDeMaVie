//
//  VehicleTypesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 30.07.2025.
//

import Foundation
import SwiftData
import Combine

import Foundation
import SwiftData

@MainActor
class VehicleTypesPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private var settings: SettingsStore?
    
    @Published var isLoading = false
    
    private let vehiclesService = VehicleService()
    @Published var vehicleTypes: [VehicleType] = []
    
    func setup(modelContext: ModelContext, settings: SettingsStore) {
        self.modelContext = modelContext
        self.settings = settings
        
        fetchFromCache()
        
        if vehicleTypes.isEmpty {
            Task {
                await refreshDataFromServer()
            }
        }
    }
    
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<VehicleType>(sortBy: [SortDescriptor(\.name)])
            self.vehicleTypes = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshDataFromServer() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            
            let dtos = try await vehiclesService.fetchVehicleTypes()
            
            var masterList: [VehicleType] = []
            for dto in dtos {
                masterList.append(
                    VehicleType(fromDto: dto)
                )
            }
            
            masterList.sort { c1, c2 in
                return c1.name < c2.name
            }
            self.vehicleTypes = masterList
            
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func cacheVehicleTypes() {
        guard let context = modelContext else {
            print("Cannot cache: model context is missing.")
            return
        }
        
        do {
            try context.delete(model: VehicleType.self)
            let typesToCache = self.vehicleTypes.filter { $0.cache }
            
            for type in typesToCache {
                context.insert(type)
            }
            try context.save()
        } catch {
            print("Failed to perform targeted cache for vehicletypes: \(error)")
        }
    }
    
    
    // MARK: - User Actions
    
    func createVehicleType(payload: NewVehicleTypePayload) async {
        guard let context = modelContext else { return }        
        do {
            let newTypeDTO = try await vehiclesService.createVehicleType(payload: payload)
            let newType = VehicleType(fromDto: newTypeDTO)
            context.insert(newType)
            try? context.save()
            fetchFromCache()
        } catch {
            print("Failed to create city: \(error)")
        }
    }
    
    /// Toggles the cache status for a vehicle type.
    func toggleCacheForVehicleType(for vehicleType: VehicleType) {
        Task {
            do {
                try await vehiclesService.updateCacheStatus(
                    forVehicleTypeId: vehicleType.id,
                    shouldCache: vehicleType.cache
                )
            } catch {
                print("Failed to update cache status on server: \(error). Reverting.")
                vehicleType.cache.toggle()
            }
        }
    }
    
    
    
    
}
