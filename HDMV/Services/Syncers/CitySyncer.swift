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
    
    override func fetchRemoteModels(date: Date?) async throws -> [CityDTO] {
        return try await citiesService.fetch(includeArchived: settings.includeArchived)
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
    
    override func resolveRelationships(for model: City) throws {
        let places = try modelContext.fetch(FetchDescriptor<Place>())
        
        for place in places where place.city?.persistentModelID == model.persistentModelID && place.cityRid == nil {
            place.cityRid = model.rid
            print("🔗 Fixed missing cityRid for Place \(place.name) -> City \(model.name)")
        }
    }
    
    override func resolveRelationships() throws {
        print("Resolving City relationships...")
        
        let countryLookup: [Int: Country] = try getLookupMap()
        
        try resolveRelationship(
            for: City.self,
            relationshipKeyPath: \City.country,
            ridKeyPath: \City.countryRid,
            lookupMap: countryLookup
        )
        
        print("All City relationships resolved.")
    }
    
}

