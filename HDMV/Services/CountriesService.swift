//
//  CountriesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//

import Foundation

final class CountriesService: SupabaseDataService<CountryDTO, CountryPayload> {
    
    init() {
        super.init(tableName: "data_countries")
    }
    
    // MARK: Semantic methods
    
    func fetchCountries(includeArchived: Bool = false) async throws -> [CountryDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createCountry(payload: CountryPayload) async throws -> CountryDTO {
        try await create(payload: payload)
    }
    
    func updateCountry(rid: Int, payload: CountryPayload) async throws -> CountryDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteCountry(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
