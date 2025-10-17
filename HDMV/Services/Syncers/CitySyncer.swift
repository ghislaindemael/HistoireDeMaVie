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
    
    override func fetchRemoteModels() async throws -> [CityDTO] {
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
    
}

