//
//  PeopleService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation

class PeopleService {
    
    private let supabaseClient = SupabaseService.shared.client
    
    func fetchAllPeople() async throws -> [PersonDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        let response = try await supabaseClient
            .from("data_people")
            .select()
            .eq("archived", value: false)
            .order("name", ascending: true)
            .execute()
        
        let data = response.data
        let decoder = DecoderFactory.dateOnlyDecoder()
        return try decoder.decode([PersonDTO].self, from: data)
    }

    
    func fetchPeopleByCache(cache: Bool) async throws -> [PersonDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        let response = try await supabaseClient
            .from("data_people")
            .select()
            .eq("archived", value: false)
            .eq("cache", value: cache)
            .order("name", ascending: true)
            .execute()
        
        let data = response.data
        let decoder = DecoderFactory.dateOnlyDecoder()
        return try decoder.decode([PersonDTO].self, from: data)
    }
    
    func createPerson(_ payload: NewPersonPayload) async throws -> PersonDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from("data_people")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updatePerson(_ person: PersonDTO) async throws {
        guard let supabaseClient = supabaseClient else { return }
        try await supabaseClient
            .from("data_people")
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
