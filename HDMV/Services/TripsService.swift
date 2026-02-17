//
//  TripsService.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation


class TripsService: SupabaseDataService<TripDTO, TripPayload> {
    
    init() {
        super.init(tableName: "my_trips")
    }
    
    // MARK: Semantic methods
    
    func createTrip(_ payload: TripPayload) async throws -> TripDTO {
        try await create(payload: payload)
    }
    
    func updateTrip(rid: Int, payload: TripPayload) async throws -> TripDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteTrip(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
    
    func fetchTrips(for date: Date) async throws -> [TripDTO] {
        try await fetchForDate(date: date)
    }
    
}
