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
    
    private let TRIPS_TABLE_NAME = "my_trips"
    private let PATHS_TABLE_NAME = "data_paths"
        
    // MARK: Trips
    
    func fetchTrips(for date: Date) async throws -> [TripDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw SyncError.dateCalculationError
        }
        
        let formatter = ISO8601DateFormatter()
        let startOfDayString = formatter.string(from: startOfDay)
        let endOfDayString = formatter.string(from: endOfDay)
        
        let endCondition = "time_end.gt.\(startOfDayString),time_end.is.null"
        
        return try await supabaseClient
            .from(TRIPS_TABLE_NAME)
            .select()
            .lt("time_start", value: endOfDayString)
            .or(endCondition)
            .order("time_start", ascending: false)
            .execute()
            .value
    }
    
    func createTrip(_ payload: TripPayload) async throws -> TripDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(TRIPS_TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateTrip(id: Int, payload: TripPayload) async throws -> TripDTO {
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
