//
//  PlaceTypesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2026.
//

import Foundation

final class PlaceTypesService: SupabaseDataService<PlaceTypeDTO, PlaceTypePayload> {
    
    init() {
        super.init(tableName: "data_place_types")
    }
    
    // MARK: Semantic methods
    
    func fetchPlaceTypes(includeArchived: Bool = false) async throws -> [PlaceTypeDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createPlaceType(payload: PlaceTypePayload) async throws -> PlaceTypeDTO {
        try await create(payload: payload)
    }
    
    func updatePlaceType(rid: Int, payload: PlaceTypePayload) async throws -> PlaceTypeDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deletePlaceType(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
