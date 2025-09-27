//
//  TripsService.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation

class TripsService {
    
    private let supabaseClient = SupabaseService.shared.client
    private let settings = SettingsStore.shared
    
    private let TRIPS_TABLE_NAME = "my_trip_legs"
    private let PATHS_TABLE_NAME = "data_paths"
        
    // MARK: TripLegs
    
    func fetchTripLegs(for date: Date) async throws -> [TripLegDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await supabaseClient
            .from(TRIPS_TABLE_NAME)
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
            .from(TRIPS_TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateTrip(id: Int, payload: TripLegPayload) async throws -> TripLegDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.badURL) }
        return try await supabaseClient
            .from(TRIPS_TABLE_NAME)
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }
    
    // MARK: Paths
    
    func fetchPaths() async throws -> [PathDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        var query = supabaseClient
            .from(PATHS_TABLE_NAME)
            .select()
        
        if !settings.includeArchived {
            query = query.eq("archived", value: false)
        }
        
        return try await query
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func createPath(payload: PathPayload) async throws -> PathDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(PATHS_TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updatePath(id: Int, payload: PathPayload) async throws -> PathDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(PATHS_TABLE_NAME)
            .update(payload, returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }
}
