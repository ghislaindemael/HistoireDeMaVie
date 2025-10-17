//
//  PlaceSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class VehicleSyncer: BaseSyncer<Vehicle, VehicleDTO, VehiclePayload> {
    
    private let vehiclesService = VehiclesService()
    private let settings: SettingsStore = SettingsStore.shared
    
    override func fetchRemoteModels() async throws -> [VehicleDTO] {
        return try await vehiclesService.fetch(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: VehiclePayload) async throws -> VehicleDTO {
        return try await vehiclesService.createVehicle(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: VehiclePayload) async throws -> VehicleDTO {
        return try await vehiclesService.updateVehicle(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Vehicle deletion not implemented")
    }
    
}

