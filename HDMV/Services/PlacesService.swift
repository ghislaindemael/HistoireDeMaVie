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
}
