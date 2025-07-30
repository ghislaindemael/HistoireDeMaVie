//
//  CountriesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//

import Foundation

class CountriesService: CountriesServiceProtocol {
    
    private let supabaseClient = SupabaseService.shared.client
    private let settings = SettingsStore.shared
    
    private let TABLE_NAME: String = "data_countries"

    
    func fetchCountries() async throws -> [CountryDTO] {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        var query = supabaseClient
            .from(TABLE_NAME)
            .select()
        
        if !settings.includeArchived {
            query = query.eq("archived", value: false)
        }
        
        return try await query
            .order("name", ascending: true)
            .execute()
            .value
    }
            
    
    func createCountry(payload: NewCountryPayload) async throws -> CountryDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from(TABLE_NAME)
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    
    func updateCacheStatus(for country: Country) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        try await supabaseClient
            .from(TABLE_NAME)
            .update(["cache": country.cache])
            .eq("id", value: country.id)
            .execute()
    }
        
    /// Sets the 'archived' column of a country to true in  supabase.
    func archiveCountry(country: Country) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }

        try await supabaseClient
            .from(TABLE_NAME)
            .update(["archived": true])
            .eq("id", value: country.id)
            .execute()
    }
    
    /// Sets the 'archived' column of a country to false in  supabase.
    func unarchiveCountry(country: Country) async throws {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }

        try await supabaseClient
            .from(TABLE_NAME)
            .update(["archived": false])
            .eq("id", value: country.id)
            .execute()
    }
    
}
