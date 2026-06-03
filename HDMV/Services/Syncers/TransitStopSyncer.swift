//
//  TransitStopSyncer.swift
//  HDMV
//

import Foundation
import SwiftData

@MainActor
final class TransitStopSyncer: BaseSyncer<TransitStop, TransitStopDTO, TransitStopPayload> {
    
    private let transitStopsService = TransitStopsService()
    
    override func fetchRemoteModels(date: Date?) async throws -> [TransitStopDTO] {
        return try await transitStopsService.fetch(includeArchived: false, orderColumn: "stop_sequence")
    }
    
    override func createOnServer(payload: TransitStopPayload) async throws -> TransitStopDTO {
        fatalError("Creation of TransitStops from within the app is not allowed. Configure via web app.")
    }
    
    override func updateOnServer(rid: Int, payload: TransitStopPayload) async throws -> TransitStopDTO {
        fatalError("Editing of TransitStops from within the app is not allowed. Configure via web app.")
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Deletion of TransitStops from within the app is not allowed. Configure via web app.")
    }
    
    override func resolveRelationships() throws {
        print("Resolving TransitStop relationships...")
        
        let lineLookup: [Int: TransitLine] = try getLookupMap()
        let stationLookup: [Int: TransitStation] = try getLookupMap()
        
        try resolveRelationship(
            for: TransitStop.self,
            relationshipKeyPath: \TransitStop.line,
            ridKeyPath: \TransitStop.lineRid,
            lookupMap: lineLookup
        )
        
        try resolveRelationship(
            for: TransitStop.self,
            relationshipKeyPath: \TransitStop.station,
            ridKeyPath: \TransitStop.stationRid,
            lookupMap: stationLookup
        )
        
        print("All TransitStop relationships resolved.")
    }
}
