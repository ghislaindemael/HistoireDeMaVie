//
//  TripLegSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData

@MainActor
class TripLegSyncer: BaseSyncer<TripLeg, TripLegDTO, TripLegPayload> {
    
    private let tripLegsService = TripsService()
    
    // MARK: - Implemented Network Methods
    
    override func createOnServer(payload: TripLegPayload) async throws -> TripLegDTO {
        return try await tripLegsService.createTrip(payload)
    }
    
    override func updateOnServer(rid: Int, payload: TripLegPayload) async throws -> TripLegDTO {
        return try await tripLegsService.updateTrip(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        // try await tripLegsService.deleteTrip(id: id)
    }
    
}
