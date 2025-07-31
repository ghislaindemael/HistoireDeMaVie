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
    
    
    func fetchVehicles() async throws -> [VehicleDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        let response: [VehicleDTO] = try await supabaseClient
            .from("data_vehicles")
            .select()
            .order("favourite", ascending: false)
            .order("type", ascending: true)
            .order("name", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Inserts a new vehicle into the database and returns the created record, including the new ID.
    func createVehicle(_ vehicle: VehicleDTO) async throws -> VehicleDTO {
        guard let supabaseClient = supabaseClient else {
            throw NSError(domain: "VehicleServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not available"])
        }
        
        let createdVehicle: VehicleDTO = try await supabaseClient
            .from("data_vehicles")
            .insert(vehicle, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        
        return createdVehicle
    }
    
    func updateVehicle(_ vehicle: VehicleDTO) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_vehicles")
            .update(vehicle)
            .eq("id", value: vehicle.id)
            .execute()
    }
    
    func deleteVehicle(id: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("vehicles")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func updateCacheStatus(
        forVehicleTypeId countryId: Int,
        shouldCache: Bool
    ) async throws {
        guard let supabaseClient = supabaseClient else {
            return
        }
        
        try await supabaseClient
            .from("data_vehicle_types")
            .update(["cache": shouldCache])
            .eq("id", value: countryId)
            .execute()
    }
    
    
    func fetchVehicleTypes() async throws -> [VehicleTypeDTO] {
        guard let supabaseClient = SupabaseService.shared.client else {
            return []
        }
        
        let response: [VehicleTypeDTO] = try await supabaseClient
            .from("data_vehicle_types")
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
    
    
}
