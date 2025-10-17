//
//  PlaceSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class PlaceSyncer: BaseSyncer<Place, PlaceDTO, PlacePayload> {
    
    private let placesService = PlacesService()
    private let settings: SettingsStore = SettingsStore.shared
    
    override func fetchRemoteModels() async throws -> [PlaceDTO] {
        return try await placesService.fetch(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: PlacePayload) async throws -> PlaceDTO {
        return try await placesService.createPlace(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: PlacePayload) async throws -> PlaceDTO {
        return try await placesService.updatePlace(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("City deletion not implemented")
    }
    
}

