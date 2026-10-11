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
    
    override func fetchRemoteModels(date: Date?) async throws -> [PlaceDTO] {
        return try await placesService.fetch(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: PlacePayload) async throws -> PlaceDTO {
        return try await placesService.createPlace(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: PlacePayload) async throws -> PlaceDTO {
        return try await placesService.updatePlace(rid: rid, payload: payload)
    }
    
    func pullChanges(cityRid: Int) async throws {
        let dtos = try await placesService.fetchPlaces(forCityId: cityRid, includeArchived: settings.includeArchived)
        let serverRids = Set(dtos.map { $0.id })
        
        let predicate = #Predicate<Place> { place in
            place.cityRid == cityRid
        }
        let descriptor = FetchDescriptor<Place>(predicate: predicate)
        let relevantLocalModels = try modelContext.fetch(descriptor)
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
            } else {
                let newModel = Place(fromDto: dto)
                modelContext.insert(newModel)
            }
        }
        
        let ridsToDelete = localRids.subtracting(serverRids)
        for rid in ridsToDelete {
            if let modelToDelete = localCache[rid], modelToDelete.syncStatus == .synced {
                modelContext.delete(modelToDelete)
            }
        }
        
        try resolveRelationships()
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("City deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        print("Resolving Place relationships...")
        
        let cityLookup: [Int: City] = try getLookupMap()
        
        try resolveRelationship(
            for: Place.self,
            relationshipKeyPath: \Place.city,
            ridKeyPath: \Place.cityRid,
            lookupMap: cityLookup
        )
        
        let placeTypeLookup: [Int: PlaceType] = try getLookupMap()
        try resolveRelationship(
            for: Place.self,
            relationshipKeyPath: \Place.placeType,
            ridKeyPath: \Place.placeTypeRid,
            lookupMap: placeTypeLookup
        )
        
        print("All Place relationships resolved.")
    }
    
}

