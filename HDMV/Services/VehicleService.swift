//
//  VehicleService.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation

class VehicleService {
    private let supabaseClient = SupabaseService.shared.client
    private let settings = SettingsStore.shared
    
    private let VEHICLES_TABLE_NAME: String = "data_vehicles"
    private let VEHICLE_TYPES_TABLE_NAME: String = "data_vehicle_types"
    
    // MARK: Vehicles
    
    func fetchVehicles() async throws -> [VehicleDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        let response: [VehicleDTO] = try await supabaseClient
            .from(VEHICLES_TABLE_NAME)
            .select()
            .order("type", ascending: true)
            .order("name", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Inserts a new vehicle into the database and returns the created record, including the new ID.
    func createVehicle(payload: NewVehiclePayload) async throws -> VehicleDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        let createdVehicle: VehicleDTO = try await supabaseClient
            .from(VEHICLES_TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        
        return createdVehicle
    }
    
    func updateCache(forVehicle vehicle: Vehicle) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        try await supabaseClient
            .from(VEHICLES_TABLE_NAME)
            .update(["cache": vehicle.cache])
            .eq("id", value: vehicle.id)
            .execute()
    }
    
    func deleteVehicle(id: Int) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        try await supabaseClient
            .from(VEHICLES_TABLE_NAME)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    

    // MARK: Vehicle types
    
    func fetchVehicleTypes() async throws -> [VehicleTypeDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        let response: [VehicleTypeDTO] = try await supabaseClient
            .from(VEHICLE_TYPES_TABLE_NAME)
            .select()
            .execute()
            .value
        return response
    }
    
    func createVehicleType(payload: NewVehicleTypePayload) async throws -> VehicleTypeDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(VEHICLE_TYPES_TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateCache(forVehicleType vehicleType: VehicleType) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        try await supabaseClient
            .from(VEHICLE_TYPES_TABLE_NAME)
            .update(["cache": vehicleType.cache])
            .eq("id", value: vehicleType.id)
            .execute()
    }
    
}
