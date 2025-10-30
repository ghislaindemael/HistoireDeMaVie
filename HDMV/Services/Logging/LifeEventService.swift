//
//  LifeEventService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//


import Foundation

class LifeEventService: SupabaseDataService<LifeEventDTO, LifeEventPayload > {
    
    init() {
        super.init(tableName: "my_life_events")
    }
    
    // MARK: Semantic methods
    
    func createLifeEvent(_ payload: LifeEventPayload) async throws -> LifeEventDTO {
        try await create(payload: payload)
    }
    
    func updateLifeEvent(rid: Int, payload: LifeEventPayload) async throws -> LifeEventDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteLifeEvent(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
    
    func fetchLifeEvents(for date: Date) async throws -> [LifeEventDTO] {
        try await fetchForDate(date: date)
    }
    
    override func fetchForDate(date: Date) async throws -> [LifeEventDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw SyncError.dateCalculationError
        }
        
        let formatter = ISO8601DateFormatter()
        let startOfDayString = formatter.string(from: startOfDay)
        let endOfDayString = formatter.string(from: endOfDay)
        
        return try await supabaseClient
            .from(tableName)
            .select()
            .gte("time_start", value: startOfDayString)
            .lt("time_start", value: endOfDayString)
            .order("time_start", ascending: false)
            .execute()
            .value
    }

    
}
