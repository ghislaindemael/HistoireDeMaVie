//
//  TransitStationSyncer.swift
//  HDMV
//

import Foundation
import SwiftData

@MainActor
final class TransitStationSyncer: BaseSyncer<TransitStation, TransitStationDTO, TransitStationPayload> {
    
    private let transitStationsService = TransitStationsService()
    
    override func fetchRemoteModels(date: Date?) async throws -> [TransitStationDTO] {
        return try await transitStationsService.fetch(includeArchived: false)
    }
    
    override func createOnServer(payload: TransitStationPayload) async throws -> TransitStationDTO {
        fatalError("Creation of TransitStations from within the app is not allowed. Configure via web app.")
    }
    
    override func updateOnServer(rid: Int, payload: TransitStationPayload) async throws -> TransitStationDTO {
        fatalError("Editing of TransitStations from within the app is not allowed. Configure via web app.")
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Deletion of TransitStations from within the app is not allowed. Configure via web app.")
    }
    
    override func resolveRelationships() throws {
        print("Resolving TransitStation relationships...")
        let placeLookup: [Int: Place] = try getLookupMap()
        
        try resolveRelationship(
            for: TransitStation.self,
            relationshipKeyPath: \TransitStation.place,
            ridKeyPath: \TransitStation.placeRid,
            lookupMap: placeLookup
        )
        print("All TransitStation relationships resolved.")
    }
}
