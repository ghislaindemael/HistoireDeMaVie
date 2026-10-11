//
//  PlaceTypeSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2026.
//

import Foundation
import SwiftData

@MainActor
final class PlaceTypeSyncer: BaseSyncer<PlaceType, PlaceTypeDTO, PlaceTypePayload> {
    
    private let placeTypesService = PlaceTypesService()
    private let settings: SettingsStore = SettingsStore.shared
    
    override func fetchRemoteModels(date: Date?) async throws -> [PlaceTypeDTO] {
        return try await placeTypesService.fetchPlaceTypes(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: PlaceTypePayload) async throws -> PlaceTypeDTO {
        return try await placeTypesService.createPlaceType(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: PlaceTypePayload) async throws -> PlaceTypeDTO {
        return try await placeTypesService.updatePlaceType(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await placeTypesService.deletePlaceType(id: id)
    }
}
