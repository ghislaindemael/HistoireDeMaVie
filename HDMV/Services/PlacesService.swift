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
