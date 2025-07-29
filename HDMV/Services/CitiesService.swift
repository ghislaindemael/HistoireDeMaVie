//
//  CitiesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation

class CitiesService {
    private let supabaseClient = SupabaseService.shared.client
        
    func fetchCities(forCountryId countryId: Int) async throws -> [CityDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        return try await supabaseClient
            .from("data_cities")
            .select()
            .eq("country_id", value: countryId)
            .eq("archived", value: false)
            .order("rank", ascending: true)
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func fetchCities() async throws -> [CityDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        return try await supabaseClient
            .from("data_cities")
            .select()
            .eq("archived", value: false)
            .order("rank", ascending: true)
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func fetchCities(includeArchived: Bool = false) async throws -> [CityDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        var query = supabaseClient
            .from("data_cities")
            .select()
        
        if !includeArchived {
            query = query.eq("archived", value: false)
        }
        
        return try await query
            .order("rank", ascending: true)
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func createCity(_ payload: NewCityPayload) async throws -> CityDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from("data_cities")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateCity(_ city: CityDTO) async throws {
        guard let supabaseClient = supabaseClient else { return }
        try await supabaseClient
            .from("data_cities")
            .update(city)
            .eq("id", value: city.id)
            .execute()
    }
    
    func updateCacheStatus(forCityId cityId: Int, shouldCache: Bool) async throws {
        guard let supabaseClient = supabaseClient else {
            return
        }
        
        try await supabaseClient
            .from("data_cities")
            .update(["cache": shouldCache])
            .eq("id", value: cityId)
            .execute()
    }
    
    func updateRank(forCityId cityId: Int, newRank: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_cities")
            .update(["rank": newRank])
            .eq("id", value: cityId)
            .execute()
    }
    
    /// Sets the 'archived' status of a city to true.
    func archiveCity(id: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_cities")
            .update(["archived": true])
            .eq("id", value: id)
            .execute()
    }
    
    /// Sets the 'archived' status of a city to false.
    func unarchiveCity(id: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_cities")
            .update(["archived": false])
            .eq("id", value: id)
            .execute()
    }
    
}
