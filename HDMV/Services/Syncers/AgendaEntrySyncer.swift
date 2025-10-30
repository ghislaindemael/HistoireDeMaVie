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
    
    private let tripsService = TripsService()
    
    override func createOnServer(payload: PathPayload) async throws -> PathDTO {
        return try await tripsService.createPath(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: PathPayload) async throws -> PathDTO {
        return try await tripsService.updatePath(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Path deletion not implemented")
    }
    
}
