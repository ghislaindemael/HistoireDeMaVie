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
    
    override func pullChanges() async throws {
        let dtos: [CountryDTO] = try await countriesService.fetch(includeArchived: settings.includeArchived)
        
        let existingCountries = try modelContext.fetch(FetchDescriptor<Country>())
        
        var localCache: [Int: Country] = Dictionary(uniqueKeysWithValues: existingCountries.compactMap { country in
            guard let rid = country.rid else { return nil }
            return (rid, country)
        })
        
        for dto in dtos {
            if let existing = localCache[dto.id] {
                existing.update(fromDto: dto)
            } else {
                let country = Country(fromDto: dto)
                modelContext.insert(country)
                localCache[country.rid!] = country
            }
            
            try modelContext.save()
        }
        
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

