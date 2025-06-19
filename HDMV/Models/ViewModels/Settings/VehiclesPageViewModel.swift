//
//  VehicleViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
class VehiclesPageViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var vehicleTypes: [VehicleType] = []
    @Published var isLoading = false

    
    private let vehicleService = VehicleService()
    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading and Caching
    
    /// Loads data first from the local cache, and if empty, fetches from the server.
    private func loadInitialData() async {
        fetchFromCache()
        
        if vehicles.isEmpty || vehicleTypes.isEmpty {
            await refreshDataFromServer()
        }
    }
    
    /// Fetches the latest data from Supabase, clears the local cache, and saves the new data.
    func refreshDataFromServer() async {
        guard let context = modelContext else { return }
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let vehicleDTOs = try await vehicleService.fetchVehicles()
            let vehicleTypeDTOs = try await vehicleService.fetchVehicleTypes()
            
            try context.delete(model: Vehicle.self)
            try context.delete(model: VehicleType.self)
            
            for dto in vehicleDTOs {
                context.insert(Vehicle(id: dto.id!, name: dto.name, favourite: dto.favourite, type: dto.type, city_id: dto.city_id))
            }
            for dto in vehicleTypeDTOs {
                context.insert(VehicleType(id: dto.id, slug: dto.slug, name: dto.name, icon: dto.icon))
            }
            
            try context.save()
            
            fetchFromCache()
            
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    /// Loads the @Published arrays from the local SwiftData cache.
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let vehicleDescriptor = FetchDescriptor<Vehicle>(sortBy: [
                SortDescriptor(\.type),
                SortDescriptor(\.name)
            ])
            let fetchedVehicles = try context.fetch(vehicleDescriptor)

            self.vehicles = fetchedVehicles.sorted { v1, v2 in
                if v1.favourite != v2.favourite {
                    return v1.favourite && !v2.favourite
                } else if v1.type != v2.type {
                    return v1.type < v2.type
                } else {
                    return v1.name < v2.name
                }
            }
            
            let typeDescriptor = FetchDescriptor<VehicleType>(sortBy: [SortDescriptor(\.name)])
            self.vehicleTypes = try context.fetch(typeDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    
    // MARK: - Write-Through CRUD Operations

    
    /// Creates a vehicle remotely and updates the local state.
    func createVehicle(name: String, type: VehicleType, city_id: Int?) async {
        guard let context = modelContext else { return }
        let newVehicleDTO = VehicleDTO(id: nil, name: name, favourite: false, type: type.id, city_id: city_id)
        
        do {
            let createdDTO = try await vehicleService.createVehicle(newVehicleDTO)
            
            guard let newId = createdDTO.id else {
                print("Error: Supabase did not return a valid ID for the new vehicle.")
                return
            }
            
            let finalVehicle = Vehicle(id: newId, name: createdDTO.name, favourite: createdDTO.favourite, type: createdDTO.type, city_id: createdDTO.city_id)
            context.insert(finalVehicle)
            try context.save()
            
            fetchFromCache()
        } catch {
            print("Failed to create vehicle: \(error)")
        }
    }
    
    /// Toggles favorite status with an optimistic update.
    func toggleFavorite(for vehicle: Vehicle) {
        guard let context = modelContext else { return }
        
        vehicle.favourite.toggle()
        
        Task {
            do {
                try await vehicleService.updateVehicle(vehicleToDTO(vehicle))
                try context.save()
            } catch {
                print("Failed to update favorite status on server: \(error). Reverting UI.")
                vehicle.favourite.toggle()
            }
        }
    }

    /// Deletes a vehicle with an optimistic update.
    func delete(vehicle: Vehicle) {
        guard let context = modelContext, let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        
        let deletedVehicle = vehicles.remove(at: index)
        
        Task {
            do {
                try await vehicleService.deleteVehicle(id: deletedVehicle.id)
                context.delete(deletedVehicle)
                try context.save()
            } catch {
                print("Failed to delete vehicle on server: \(error). Reverting UI.")
                vehicles.insert(deletedVehicle, at: index)
            }
        }
    }
    
    func vehicleLabel(for vehicle: Vehicle) -> String {
        let typeName = vehicleTypes.first { $0.id == vehicle.type }?.name ?? "Unknown Type"
        if let cityId = vehicle.city_id {
            return "\(typeName) - \(cityId) - \(vehicle.name)"
        } else {
            return "\(typeName) - \(vehicle.name)"
        }
    }
}
