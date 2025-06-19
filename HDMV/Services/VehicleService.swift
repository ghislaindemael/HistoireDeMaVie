//
//  VehicleService.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation

class VehicleService {
    private let supabaseClient = SupabaseService.shared.client
    
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
        
        // Use single() to ensure we get exactly one record back.
        // Supabase returns the newly created row by default.
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
    
    
}
