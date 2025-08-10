//
//  PeopleService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation

class PeopleService {
    
    private let supabaseClient = SupabaseService.shared.client
    private let settings = SettingsStore.shared
    
    private let TABLE_NAME = "data_people"
        
    func fetchPeople() async throws -> [PersonDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        var query = supabaseClient
            .from(TABLE_NAME)
            .select()
        
        if !settings.includeArchived {
            query = query.eq("archived", value: false)
        }
        
        let response = try await query.execute()
        
        let decoder = DecoderFactory.dateOnlyDecoder()
        let people = try decoder.decode([PersonDTO].self, from: response.data)
        
        return people
    }
    
    
    func createPerson(_ payload: NewPersonPayload) async throws -> PersonDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        let response = try await supabaseClient
            .from(TABLE_NAME)
            .insert(payload)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.dateOnly)
        
        let dtos = try decoder.decode([PersonDTO].self, from: response.data)
        guard let person = dtos.first else {
            throw URLError(.cannotParseResponse)
        }
        return person
    }

    
    func updatePerson(_ person: PersonDTO) async throws {
        guard let supabaseClient = supabaseClient else { return }
        try await supabaseClient
            .from(TABLE_NAME)
            .update(person)
            .eq("id", value: person.id)
            .execute()
    }
    
    func updateCacheStatus(forPersonId personId: Int, isActive: Bool) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_people")
            .update(["cache": isActive])
            .eq("id", value: personId)
            .execute()
    }
    
    /// Archives a person by setting its 'archived' flag to true on the server.
    func archivePerson(forPersonId: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        try await supabaseClient
            .from("data_people")
            .update(["archived": true])
            .eq("id", value: forPersonId)
            .execute()
    }
    
}
