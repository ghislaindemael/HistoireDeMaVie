//
//  TripsService.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation

class TripsService {
    private let supabaseClient = SupabaseService.shared.client
    
    func fetchTrips(for date: Date) async throws -> [TripDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await supabaseClient
            .from("my_trips")
            .select()
            .gte("time_start", value: ISO8601DateFormatter().string(from: startOfDay))
            .lt("time_start", value: ISO8601DateFormatter().string(from: endOfDay))
            .order("time_start", ascending: true)
            .execute()
            .value
    }
    
    func createTrip(_ payload: TripPayload) async throws -> TripDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from("my_trips")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateTrip(id: Int, payload: TripPayload) async throws -> TripDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.badURL) }
        return try await supabaseClient
            .from("my_trips")
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }
}
