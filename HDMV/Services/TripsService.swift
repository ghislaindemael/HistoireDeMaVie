//
//  TripsService.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation

class TripsService {
    private let supabaseClient = SupabaseService.shared.client
    
    private let TABLE_NAME = "my_trip_legs"
        
    func fetchTripLegs(for date: Date) async throws -> [TripLegDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await supabaseClient
            .from(TABLE_NAME)
            .select()
            .gte("time_start", value: ISO8601DateFormatter().string(from: startOfDay))
            .lt("time_start", value: ISO8601DateFormatter().string(from: endOfDay))
            .order("time_start", ascending: false)
            .execute()
            .value
    }
    
    func createTrip(_ payload: TripLegPayload) async throws -> TripLegDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateTrip(id: Int, payload: TripLegPayload) async throws -> TripLegDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.badURL) }
        return try await supabaseClient
            .from(TABLE_NAME)
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }
}
