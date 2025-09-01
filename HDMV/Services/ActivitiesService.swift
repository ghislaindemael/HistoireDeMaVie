//
//  ActivitiesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation

/// The concrete implementation of `ActivitiesServiceProtocol`.
/// This class is responsible for making network requests to a backend service
/// (e.g., Supabase) to manage `Activity` data.
class ActivitiesService: ActivitiesServiceProtocol {
    
    private let supabaseClient = SupabaseService.shared.client
    private let settings = SettingsStore.shared
    
    private let TABLE_NAME: String = "data_activities"
    
    func fetchActivities() async throws -> [ActivityDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        var query = supabaseClient
            .from(TABLE_NAME)
            .select()
        
        if !settings.includeArchived {
            query = query.eq("archived", value: false)
        }
        
        return try await query
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func createActivity(payload: ActivityPayload) async throws -> ActivityDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateActivity(id: Int, payload: ActivityPayload) async throws -> ActivityDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(TABLE_NAME)
            .update(payload, returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateCacheStatus(for activity: Activity) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        try await supabaseClient
            .from(TABLE_NAME)
            .update(["cache": activity.cache])
            .eq("id", value: activity.id)
            .execute()
    }
    
    func archiveActivity(for activity: Activity) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        try await supabaseClient
            .from(TABLE_NAME)
            .update(["archived": true])
            .eq("id", value: activity.id)
            .execute()
    }
    
    func unarchiveActivity(for activity: Activity) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        try await supabaseClient
            .from(TABLE_NAME)
            .update(["archived": false])
            .eq("id", value: activity.id)
            .execute()
    }
}

