//
//  ActivityInstanceService.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//


import Foundation

class ActivityInstanceService: SupabaseDataService<ActivityInstanceDTO, ActivityInstancePayload> {
    
    init() {
        super.init(tableName: "my_activities")
    }
    
    // MARK: Semantic methods
    
    func createActivityInstance(_ payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        try await create(payload: payload)
    }
    
    func updateActivityInstance(rid: Int, payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteActivityInstance(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
    
    func fetchActivityInstances(for date: Date) async throws -> [ActivityInstanceDTO] {
        try await fetchForDate(date: date)
    }
    
    /// A flexible function to fetch instances from the server based on a date range and an optional activity ID.
    func fetchActivityInstances(
        activityId: Int,
        startDate: Date,
        endDate: Date
    ) async throws -> [ActivityInstanceDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        let formatter = ISO8601DateFormatter()
        
        let query = supabaseClient
            .from(tableName)
            .select()
            .eq("activity_id", value: activityId)
            .gte("time_start", value: formatter.string(from: startDate))
            .lt("time_start", value: formatter.string(from: endDate))
        
        return try await query
            .order("time_start", ascending: false)
            .execute()
            .value
    }
    
}
