//
//  TransactionService.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import Foundation

class TransactionService: SupabaseDataService<TransactionDTO, TransactionPayload> {
    
    init() {
        super.init(tableName: "my_transactions")
    }
    
    // MARK: - Semantic Methods (Using Base Class)
    
    func createTransaction(_ payload: TransactionPayload) async throws -> TransactionDTO {
        try await create(payload: payload)
    }
    
    func updateTransaction(rid: Int, payload: TransactionPayload) async throws -> TransactionDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteTransaction(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
    
    // MARK: - Custom Fetch Methods (Bypassing Base Class)
    
    /// Fetches all transactions that occurred on a specific date using the `time` column
    func fetchTransactions(for date: Date) async throws -> [TransactionDTO] {
        guard let client = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw SyncError.dateCalculationError
        }
        
        let formatter = ISO8601DateFormatter()
        let startOfDayString = formatter.string(from: startOfDay)
        let endOfDayString = formatter.string(from: endOfDay)
        
        return try await client
            .from(tableName)
            .select()
            .gte("time", value: startOfDayString)
            .lt("time", value: endOfDayString)
            .order("time", ascending: false)
            .execute()
            .value
    }
    
    /// Fetches transactions for a specific parent instance within a date range
    func fetchTransactions(
        parentInstanceId: Int,
        startDate: Date,
        endDate: Date
    ) async throws -> [TransactionDTO] {
        guard let client = supabaseClient else { return [] }
        
        let formatter = ISO8601DateFormatter()
        
        let query = client
            .from(tableName)
            .select()
            .eq("parent_instance_id", value: parentInstanceId)
            .gte("time", value: formatter.string(from: startDate))
            .lt("time", value: formatter.string(from: endDate))
        
        return try await query
            .order("time", ascending: false)
            .execute()
            .value
    }
}
