//
//  VaultTaskService.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.03.2026.
//


import Foundation

class VaultTaskService: SupabaseDataService<VaultTaskDTO, VaultTaskPayload> {
    
    init() {
        super.init(tableName: "my_tasks")
    }
    
    // MARK: - Semantic methods
    
    func fetchTasks(for date: Date) async throws -> [VaultTaskDTO] {
        try await fetchForDate(date: date)
    }
    
    /// Optional: A custom fetch if you want to pull ALL pending tasks regardless of date.
    func fetchAllPendingTasks() async throws -> [VaultTaskDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        return try await supabaseClient
            .from(tableName)
            .select()
            .neq("status", value: "completed")
            .neq("status", value: "canceled")
            .order("priority", ascending: false)
            .execute()
            .value
    }
    
    func createTask(_ payload: VaultTaskPayload) async throws -> VaultTaskDTO {
        try await create(payload: payload)
    }
    
    func updateTask(id: Int, payload: VaultTaskPayload) async throws -> VaultTaskDTO {
        try await update(rid: id, payload: payload)
    }
    
    func deleteTask(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
