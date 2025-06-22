//
//  CitiesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation

class CitiesService {
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
    
    /// Fetches ONLY the cities that are marked for caching and are not archived.
    func fetchCachableCities() async throws -> [CityDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        return try await supabaseClient
            .from("data_cities")
            .select()
            .eq("archived", value: false)
            .eq("cache", value: true)
            .order("rank", ascending: true)
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func fetchUncachableCities() async throws -> [CityDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        return try await supabaseClient
            .from("data_cities")
            .select()
            .eq("archived", value: false)
            .eq("cache", value: false)
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
        guard let supabaseClient = supabaseClient, let cityId = city.id else { return }
        try await supabaseClient
            .from("data_cities")
            .update(city)
            .eq("id", value: cityId)
            .execute()
    }
    
    func updateCacheStatus(forCityId cityId: Int, isActive: Bool) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_cities")
            .update(["cache": isActive])
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
    
    func archiveCity(id: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_cities")
            .update(["archived": true])
            .eq("id", value: id)
            .execute()
    }
    
}
