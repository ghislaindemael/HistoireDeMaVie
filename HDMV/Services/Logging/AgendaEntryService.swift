//
//  LifeEventService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//


import Foundation

class AgendaEntryService: SupabaseDataService<AgendaEntryDTO, AgendaEntryPayload> {
    
    init() {
        super.init(tableName: "my_agenda")
    }
    
    // MARK: Semantic methods
    
    func upsertAgendaEntry(_ payload: AgendaEntryPayload) async throws -> AgendaEntryDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        return try await supabaseClient
            .from(tableName)
            .upsert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func deleteAgendaEntry(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
    
    func fetchAgendaEntry(for date: Date) async throws -> AgendaEntryDTO? {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        let dayNumber = DayCalculator.dayNumber(for: date)
        
        print("Fetching AgendaEntry for date: \(date), day number (rid): \(dayNumber)")
        
        return try await supabaseClient
            .from(tableName)
            .select()
            .eq("id", value: dayNumber)
            .single()
            .execute()
            .value
    }
    
}
