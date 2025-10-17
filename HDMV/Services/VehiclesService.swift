//
//  PlacesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation


final class VehiclesService: SupabaseCatalogueService<VehicleDTO, VehiclePayload> {
    
    init() {
        super.init(tableName: "data_vehicles")
    }
    
    // MARK: Semantic methods
    
    func fetchVehicles(includeArchived: Bool = false) async throws -> [VehicleDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createVehicle(payload: VehiclePayload) async throws -> VehicleDTO {
        try await create(payload: payload)
    }
    
    func updateVehicle(rid: Int, payload: VehiclePayload) async throws -> VehicleDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteVehicle(rid: Int) async throws -> Bool {
        try await delete(rid: rid)
    }
}
