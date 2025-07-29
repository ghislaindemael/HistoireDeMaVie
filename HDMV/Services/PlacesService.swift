//
//  PlacesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation

class PlacesService {
    private let supabaseClient = SupabaseService.shared.client
    
    func fetchPlaces() async throws -> [PlaceDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        return try await supabaseClient
            .from("data_places")
            .select()
            .eq("archived", value: false)
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func fetchPlaces(
        forCityId cityId: Int,
        includeArchived: Bool = false
    ) async throws -> [PlaceDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        var query = supabaseClient
            .from("data_places")
            .select()
            .eq("city_id", value: cityId)
        
        if !includeArchived {
            query = query.eq("archived", value: false)
        }
        
        return try await query
            .order("name", ascending: true)
            .execute()
            .value
    }

    func createPlace(_ payload: NewPlacePayload) async throws -> PlaceDTO {
        guard let supabaseClient = supabaseClient else { throw URLError(.cannotConnectToHost) }
        return try await supabaseClient
            .from("data_places")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updatePlace(_ place: PlaceDTO) async throws {
        guard let supabaseClient = supabaseClient else { return }
        try await supabaseClient
            .from("data_places")
            .update(place)
            .eq("id", value: place.id)
            .execute()
    }
    
    func updateCacheStatus(forPlaceId placeId: Int, isActive: Bool) async throws {
        guard let supabaseClient = supabaseClient else { return }
        
        try await supabaseClient
            .from("data_places")
            .update(["cache": isActive])
            .eq("id", value: placeId)
            .execute()
    }
    
    /// Archives a place by setting its 'archive' flag to true on the server.
    func archivePlace(forPlaceId: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        try await supabaseClient
            .from("data_places")
            .update(["archived": true])
            .eq("id", value: forPlaceId)
            .execute()
    }
    
    func unarchivePlace(forPlaceId: Int) async throws {
        guard let supabaseClient = supabaseClient else { return }
        try await supabaseClient
            .from("data_places")
            .update(["archived": false])
            .eq("id", value: forPlaceId)
            .execute()
    }
    
}
