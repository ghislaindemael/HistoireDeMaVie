//
//  AgendaService.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//


import Foundation

class AgendaService {
    private let supabaseClient = SupabaseService.shared.client
    
    /// Fetches a single agenda entry for a given date.
    /// Returns nil if no entry exists for that date.
    func fetchAgenda(for date: Date) async throws -> AgendaDTO? {
        guard let supabase = self.supabaseClient else {
            throw NSError(domain: "AgendaServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized."])
        }
        
        let dateString = ISO8601DateFormatter.justDate.string(from: date)
        
        let response: [AgendaDTO] = try await supabase
            .from("my_agenda")
            .select()
            .eq("date", value: dateString)
            .limit(1)
            .execute()
            .value
            
        return response.first
    }
    
    func insertAgenda(_ agendaDto: AgendaDTO) async throws -> AgendaDTO {
        guard let supabase = self.supabaseClient else {
            throw NSError(domain: "AgendaServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized."])
        }
        
        let insertedRows: [AgendaDTO] = try await supabase
            .from("my_agenda")
            .insert(agendaDto, returning: .representation)
            .select()
            .execute()
            .value
        
        print(insertedRows)
        
        guard let newAgenda = insertedRows.first else {
            throw NSError(domain: "AgendaServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode inserted agenda."])
        }
        return newAgenda
    }
    
    func updateAgenda(_ agendaDto: AgendaDTO) async throws {
        guard let supabase = self.supabaseClient else {
            throw NSError(domain: "AgendaServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized."])
        }
        
        try await supabase
            .from("my_agenda")
            .update(agendaDto)
            .eq("date", value: agendaDto.date)
            .execute()
    }
}
