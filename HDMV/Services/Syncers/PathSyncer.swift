//
//  PathSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class PathSyncer: BaseSyncer<Path, PathDTO, PathPayload> {
    
    private let pathService = PathService()
    private let settings: SettingsStore = SettingsStore.shared
    
    override func fetchRemoteModels(date: Date? = nil) async throws -> [PathDTO] {
        return try await pathService.fetchPaths(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: PathPayload) async throws -> PathDTO {
        return try await pathService.createPath(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: PathPayload) async throws -> PathDTO {
        return try await pathService.updatePath(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Path deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        print("Resolving Path relationships...")
        
        let placeLookup: [Int: Place] = try getLookupMap()
        
        try resolveRelationship(
            for: Path.self,
            relationshipKeyPath: \Path.placeStart,
            ridKeyPath: \Path.placeStartRid,
            lookupMap: placeLookup
        )
        
        try resolveRelationship(
            for: Path.self,
            relationshipKeyPath: \Path.placeEnd,
            ridKeyPath: \Path.placeEndRid,
            lookupMap: placeLookup
        )
        
        print("All Path relationships resolved.")
    }
    
}
