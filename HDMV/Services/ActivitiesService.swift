//
//  ActivitiesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation

final class ActivitiesService: SupabaseCatalogueService<ActivityDTO, ActivityPayload> {
    
    init() {
        super.init(tableName: "data_activities")
    }
    
    // MARK: Semantic methods
    
    func fetchActivities(includeArchived: Bool = false) async throws -> [ActivityDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createActivity(payload: ActivityPayload) async throws -> ActivityDTO {
        try await create(payload: payload)
    }
    
    func updateActivity(rid: Int, payload: ActivityPayload) async throws -> ActivityDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteActivity(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
