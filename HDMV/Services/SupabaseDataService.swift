//
//  SupabaseCatalogueService.swift
//  HDMV
//
//  Created by Ghislain Demael on 13.10.2025.
//


import Foundation

class SupabaseDataService<DTO: Identifiable & Codable, Payload: Codable>: DataServiceProtocol {
    
    let supabaseClient = SupabaseService.shared.client
    let tableName: String
    
    init(tableName: String) {
        self.tableName = tableName
    }
    
    // MARK: - Generic fetch
    func fetch(includeArchived: Bool) async throws -> [DTO] {
        guard let client = supabaseClient else { throw URLError(.cannotConnectToHost) }
        var query = client.from(tableName).select()
        if !includeArchived {
            query = query.eq("archived", value: false)
        }
        return try await query.order("name", ascending: true)
            .execute()
            .value
    }
    
    func fetchForDate(date: Date) async throws -> [DTO] {
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
            .from(tableName)
            .select()
            .lt("time_start", value: endOfDayString)
            .or(endCondition)
            .order("time_start", ascending: false)
            .execute()
            .value
    }
    
    // MARK: - Generic create
    func create(payload: Payload) async throws -> DTO {
        guard let client = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await client
            .from(tableName)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    // MARK: - Generic update
    func update(rid: Int, payload: Payload) async throws -> DTO {
        guard let client = supabaseClient else { throw URLError(.badURL) }
        return try await client
            .from(tableName)
            .update(payload)
            .eq("id", value: rid)
            .select()
            .single()
            .execute()
            .value
    }
    
    // MARK: - Generic delete
    func delete(rid: Int) async throws -> Bool {
        guard let client = supabaseClient else { throw URLError(.badURL) }
        _ = try await client
            .from(tableName)
            .delete()
            .eq("id", value: rid)
            .execute()
        return true
    }
}
