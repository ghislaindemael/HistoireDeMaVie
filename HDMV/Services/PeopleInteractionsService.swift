//
//  PeopleInteractionsService.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import Foundation
import Supabase

class PeopleInteractionsService {
    
    private let supabaseClient: SupabaseClient? = SupabaseService.shared.client
    
    func fetchInteractions(for date: Date) async throws -> [PersonInteraction] {
        guard let supabaseClient = supabaseClient else {
            throw URLError(.cannotConnectToHost)
        }
        
        let dateString = ISO8601DateFormatter.justDate.string(from: date)
        
        let response = try await supabaseClient
            .from("my_people_interactions")
            .select()
            .eq("date", value: dateString)
            .execute()
        
        let data = response.data
        let decoder = DecoderFactory.dateOnlyDecoder()
        let dtos = try decoder.decode([PersonInteractionDTO].self, from: data)
        return dtos.map(PersonInteraction.init(fromDTO:))
    }
    
    func insertInteraction(payload: NewPersonInteractionPayload) async throws -> PersonInteraction {
        guard let supabaseClient = supabaseClient else {
            throw URLError(.cannotConnectToHost)
        }
        
        let response = try await supabaseClient
            .from("my_people_interactions")
            .insert(payload)
            .select()
            .execute()
        
        let data = response.data
        let decoder = DecoderFactory.dateOnlyDecoder()
        let dtos = try decoder.decode([PersonInteractionDTO].self, from: data)
        
        guard let dto = dtos.first else {
            throw URLError(.cannotParseResponse)
        }
        return PersonInteraction(fromDTO: dto)
    }


    
    func updateInteraction(interaction: PersonInteraction) async throws -> PersonInteraction {
        guard let supabaseClient = supabaseClient else {
            throw URLError(.cannotConnectToHost)
        }
        
        let timeFormatter = DateFormatter.timeOnly

        let dto = PersonInteractionDTO(
            id: interaction.id,
            date: interaction.date,
            time_start: timeFormatter.string(from: interaction.time_start),
            time_end: interaction.time_end != nil ? timeFormatter.string(from: interaction.time_end!) : nil,
            person_id: interaction.person_id,
            in_person: interaction.in_person,
            details: interaction.details,
            percentage: interaction.percentage
        )
        
        
        let response = try await supabaseClient
            .from("my_people_interactions")
            .update(dto)
            .eq("id", value: interaction.id)
            .select("*")
            .execute()
        
        let data = response.data
        
        guard !data.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        
        let decoder = DecoderFactory.dateOnlyDecoder()
        let dtos = try decoder.decode([PersonInteractionDTO].self, from: data)
        guard let updatedDTO = dtos.first else {
            throw URLError(.cannotParseResponse)
        }
        return PersonInteraction(fromDTO: updatedDTO)
    }
    
}

