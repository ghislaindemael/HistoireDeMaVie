//
//  ActivityInstanceService.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//


import Foundation

class ActivityInstanceService {
    
    private let supabaseClient = SupabaseService.shared.client
    private let settings = SettingsStore.shared
    
    private let TABLE_NAME = "my_activities"
    
    func fetchActivityInstances(for date: Date) async throws -> [ActivityInstanceDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
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
    
    func createActivityInstance(_ payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateActivityInstance(id: Int, payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
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
