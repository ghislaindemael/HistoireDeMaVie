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
    
    override func updateOnServer(id: Int, payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        return try await instanceService.updateActivityInstance(id: id, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        //try await instanceService.deleteActivityInstance(id: id)
    }
    
    // MARK: - Custom Logic for Updating Children
    
    /// This is the special logic to solve your parent ID update problem.
    override func updateChildrenWithNewParentIDs(_ idMap: [Int: Int]) async throws {
        guard !idMap.isEmpty else { return }
        
        let tempIds = Array(idMap.keys)
        
        let instancePredicate = #Predicate<ActivityInstance> { instance in
            instance.parent != nil && tempIds.contains(instance.parent!.id)
        }
        let childInstances = try modelContext.fetch(FetchDescriptor(predicate: instancePredicate))
        for child in childInstances {
            if let oldParentId = child.parent?.id, let newParentId = idMap[oldParentId] {
                let newParentPredicate = #Predicate<ActivityInstance> { $0.id == newParentId }
                if let newParent = try modelContext.fetch(FetchDescriptor(predicate: newParentPredicate)).first {
                    child.parent = newParent
                }
            }
        }
        
        //TODO: COMPLETE SYNC
        try modelContext.save()
    }
}
