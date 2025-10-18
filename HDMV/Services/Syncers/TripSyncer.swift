//
//  TripLegSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData

@MainActor
class TripSyncer: BaseSyncer<Trip, TripDTO, TripPayload> {
    
    private let tripLegsService = TripsService()
    
    // MARK: - Implemented Network Methods
    
    override func createOnServer(payload: TripPayload) async throws -> TripDTO {
        return try await tripLegsService.createTrip(payload)
    }
    
    override func updateOnServer(rid: Int, payload: TripPayload) async throws -> TripDTO {
        return try await tripLegsService.updateTrip(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        // try await tripLegsService.deleteTrip(id: id)
    }
    
}
