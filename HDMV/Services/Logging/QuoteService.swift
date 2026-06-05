//
//  QuoteService.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation

class QuoteService: SupabaseDataService<QuoteDTO, QuotePayload> {
    
    init() {
        super.init(tableName: "my_quotes")
    }
    
    // MARK: Semantic methods
    
    func createQuote(_ payload: QuotePayload) async throws -> QuoteDTO {
        try await create(payload: payload)
    }
    
    func updateQuote(rid: Int, payload: QuotePayload) async throws -> QuoteDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteQuote(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
    
    func fetchQuotes(for date: Date) async throws -> [QuoteDTO] {
        try await fetchForDate(date: date)
    }
    
    override func fetchForDate(date: Date) async throws -> [QuoteDTO] {
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
            .gte("date", value: startOfDayString)
            .lt("date", value: endOfDayString)
            .order("date", ascending: false)
            .execute()
            .value
    }
}
