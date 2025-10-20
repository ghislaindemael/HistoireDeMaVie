//
//  CountriesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//

import Foundation

final class CitiesService: SupabaseDataService<CityDTO, CityPayload> {
    
    init() {
        super.init(tableName: "data_cities")
    }
    
    // MARK: Semantic methods
    
    func fetchCities(includeArchived: Bool = false) async throws -> [CityDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createCity(payload: CityPayload) async throws -> CityDTO {
        try await create(payload: payload)
    }
    
    func updateCity(rid: Int, payload: CityPayload) async throws -> CityDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteCity(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
