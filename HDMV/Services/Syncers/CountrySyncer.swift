//
//  PathSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class CountrySyncer: BaseSyncer<Country, CountryDTO, CountryPayload> {
    
    private let countriesService = CountriesService()
    private let settings: SettingsStore = SettingsStore.shared
        
    override func fetchRemoteModels() async throws -> [CountryDTO] {
        return try await countriesService.fetchCountries(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: CountryPayload) async throws -> CountryDTO {
        return try await countriesService.createCountry(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: CountryPayload) async throws -> CountryDTO {
        return try await countriesService.updateCountry(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Country deletion not implemented")
    }
    
}

