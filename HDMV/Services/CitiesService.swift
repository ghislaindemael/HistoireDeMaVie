//
//  CitiesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


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
}
