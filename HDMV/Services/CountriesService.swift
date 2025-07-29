//
//  CountriesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//

import Foundation

class CountriesService {
    private let supabaseClient = SupabaseService.shared.client
    
    func fetchCountries() async throws -> [CountryDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        return try await supabaseClient
            .from("data_countries")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
    }
            
    func fetchCountries(includeArchived: Bool = false) async throws -> [CountryDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        var query = supabaseClient
            .from("data_countries")
            .select()
        
        if !includeArchived {
            query = query.eq("archived", value: false)
        }
        
        return try await query
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func createCountry(_ payload: NewCountryPayload) async throws -> CountryDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from("data_countries")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    
    func updateCacheStatus(
        forCountryId countryId: Int,
        shouldCache: Bool
    ) async throws {
        guard let supabaseClient = supabaseClient else {
            return
        }
        
        try await supabaseClient
            .from("data_countries")
            .update(["cache": shouldCache])
            .eq("id", value: countryId)
            .execute()
    }
        
    /// Sets the 'archived' status of a country to true.
    func archiveCountry(id: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_countries")
            .update(["archived": true])
            .eq("id", value: id)
            .execute()
    }
    
    /// Sets the 'archived' status of a country to false.
    func unarchiveCountry(id: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_countries")
            .update(["archived": false])
            .eq("id", value: id)
            .execute()
    }
    
}
