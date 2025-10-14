//
//  PathSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class CitySyncer: BaseSyncer<City, CityDTO, CityPayload> {
    
    private let citiesService = CitiesService()
    private let settings: SettingsStore = SettingsStore.shared
    
    override func pullChanges() async throws {
        let dtos: [CityDTO] = try await citiesService.fetch(includeArchived: settings.includeArchived)
        
        let existingCities = try modelContext.fetch(FetchDescriptor<City>())
        
        var localCache: [Int: City] = Dictionary(uniqueKeysWithValues: existingCities.compactMap { city in
            guard let rid = city.rid else { return nil }
            return (rid, city)
        })
        
        for dto in dtos {
            if let existing = localCache[dto.id] {
                existing.update(fromDto: dto)
            } else {
                let city = City(fromDto: dto)
                modelContext.insert(city)
                localCache[city.rid!] = city
            }
            
            try modelContext.save()
        }
        
    }
    
    override func createOnServer(payload: CityPayload) async throws -> CityDTO {
        return try await citiesService.createCity(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: CityPayload) async throws -> CityDTO {
        return try await citiesService.updateCity(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("City deletion not implemented")
    }
    
}

