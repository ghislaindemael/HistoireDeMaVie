//
//  ActivityInstanceSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData

@MainActor
class ActivityInstanceSyncer: BaseSyncer<ActivityInstance, ActivityInstanceDTO, ActivityInstancePayload> {
    
    private let instanceService = ActivityInstanceService()

    // MARK: - Implemented Network Methods
        
    override func createOnServer(payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        return try await instanceService.createActivityInstance(payload)
    }
    
    override func updateOnServer(rid: Int, payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        return try await instanceService.updateActivityInstance(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        //try await instanceService.deleteActivityInstance(id: id)
    }
        
    
}
