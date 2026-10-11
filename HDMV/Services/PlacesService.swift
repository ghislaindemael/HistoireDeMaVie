//
//  PlacesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation


final class PlacesService: SupabaseDataService<PlaceDTO, PlacePayload> {
    
    init() {
        super.init(tableName: "data_places")
    }
    
    // MARK: Semantic methods
    
    func fetchPlaces(includeArchived: Bool = false) async throws -> [PlaceDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func fetchPlaces(forCityId cityId: Int, includeArchived: Bool = false) async throws -> [PlaceDTO] {
        guard let client = supabaseClient else { throw URLError(.cannotConnectToHost) }
        
        var allResults: [PlaceDTO] = []
        let limit = 1000
        var offset = 0
        var hasMore = true
        
        while hasMore {
            var query = client.from(tableName).select()
            query = query.eq("city_id", value: cityId)
            if !includeArchived {
                query = query.eq("archived", value: false)
            }
            
            let batch: [PlaceDTO] = try await query
                .order("name", ascending: true)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            allResults.append(contentsOf: batch)
            
            if batch.count < limit {
                hasMore = false
            } else {
                offset += limit
            }
        }
        
        return allResults
    }
    
    func createPlace(payload: PlacePayload) async throws -> PlaceDTO {
        try await create(payload: payload)
    }
    
    func updatePlace(rid: Int, payload: PlacePayload) async throws -> PlaceDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deletePlace(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
