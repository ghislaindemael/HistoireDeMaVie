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
    @Published var cities: [City] = []

    
    private let vehicleService = VehicleService()
    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    /// Fetches the latest data from Supabase, clears the local cache, and saves the new data.
    func fetchFromServer() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let vehicleDtos = try await vehicleService.fetchVehicles()
            
            self.vehicles = vehicleDtos.map { dto in
                let vehicle = Vehicle(fromDto: dto)
                
                let icon = vehicleTypes.first { $0.id == vehicle.type }?.icon ?? "(?)"
                
                let cityName = cities.first { $0.id == vehicle.city_id }?.name
                let cityLabel: String
                if let cityName = cityName, !cityName.isEmpty {
                    cityLabel = cityName
                } else if let cityId = vehicle.city_id {
                    cityLabel = "City \(cityId)"
                } else {
                    cityLabel = ""
                }
                
                if cityLabel.isEmpty {
                    vehicle.label = "\(icon) - \(vehicle.name)"
                } else {
                    vehicle.label = "\(icon) - \(cityLabel) - \(vehicle.name)"
                }
                
                return vehicle
            }
            
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
                if v1.type != v2.type {
                    return v1.type < v2.type
                } else {
                    return v1.name < v2.name
                }
            }
            
            let typeDescriptor = FetchDescriptor<VehicleType>(sortBy: [SortDescriptor(\.name)])
            self.vehicleTypes = try context.fetch(typeDescriptor)
            
            let cityDescriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.name)])
            self.cities = try context.fetch(cityDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func cacheVehicles() {
        guard let context = modelContext else {
            print("Cannot cache: model context is missing.")
            return
        }
        
        do {
            try context.delete(model: Vehicle.self)
            for vehicle in self.vehicles.filter({ $0.cache }) {
                context.insert(vehicle)
            }
            try context.save()
        } catch {
            print("Failed to perform targeted cache for vehicletypes: \(error)")
        }
    }
    
    
    // MARK: - Write-Through CRUD Operations

    
    /// Creates a vehicle remotely and updates the local state.
    func createVehicle(payload: NewVehiclePayload) async {
        do {
            let createdDTO = try await vehicleService.createVehicle(payload: payload)
            let createdVehicle = Vehicle(fromDto: createdDTO)
            self.vehicles.append(createdVehicle)
        } catch {
            print("Failed to create vehicle: \(error)")
        }
    }
    
    /// Toggles cache status with an optimistic update.
    func toggleCache(for vehicle: Vehicle) {
        guard let context = modelContext else { return }
                
        Task {
            do {
                print("Toggling cache to \(vehicle.cache)")
                try await vehicleService.updateCache(forVehicle: vehicle)
                try context.save()
            } catch {
                print("Failed to update favorite status on server: \(error). Reverting UI.")
                vehicle.cache.toggle()
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

}
