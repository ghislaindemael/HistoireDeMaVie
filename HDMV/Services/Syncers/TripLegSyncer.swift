//
//  TripLegSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData

@MainActor
class TripLegSyncer: BaseSyncer<TripLeg, TripLegDTO, TripLegPayload> {
    
    private let tripLegsService = TripsService()
    
    // MARK: - Implemented Network Methods
    
    override func createOnServer(payload: TripLegPayload) async throws -> TripLegDTO {
        return try await tripLegsService.createTrip(payload)
    }
    
    override func updateOnServer(id: Int, payload: TripLegPayload) async throws -> TripLegDTO {
        return try await tripLegsService.updateTrip(id: id, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        // try await tripLegsService.deleteTrip(id: id)
    }
    
    override func updateChildrenWithNewParentIDs(_ idMap: [Int: Int]) async throws {
        // This method is called with the map of [oldInstanceId: newInstanceId]
        guard !idMap.isEmpty else { return }
        
        // Get all the old temporary IDs we need to search for.
        let tempParentIds = Array(idMap.keys)
        
        // Create a predicate to find all TripLegs whose parent_id is one of the old temporary IDs.
        let predicate = #Predicate<TripLeg> { leg in
            // The '?? -1' is a safeguard in case parent_id is nil.
            tempParentIds.contains(leg.parent_id ?? -1)
        }
        
        // Fetch the affected children from the local database.
        let childLegsToUpdate = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        
        // Loop through the children and update their parent_id.
        for leg in childLegsToUpdate {
            if let oldParentId = leg.parent_id, let newParentId = idMap[oldParentId] {
                print("Updating TripLeg \(leg.id)'s parent from \(oldParentId) to \(newParentId)")
                leg.parent_id = newParentId
                
                // Mark the leg as needing an update if it wasn't already marked for sync
                if leg.syncStatus == .synced {
                    leg.syncStatus = .local // Or .modified if you add it
                }
            }
        }
        
        // Save the changes to the local database.
        try modelContext.save()
    }
}
