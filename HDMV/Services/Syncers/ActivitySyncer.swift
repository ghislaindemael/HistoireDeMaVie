//
//  ActivitySyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 18.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class ActivitySyncer: BaseSyncer<Activity, ActivityDTO, ActivityPayload> {
    
    private let activitiesService = ActivitiesService()
    private let settings: SettingsStore = SettingsStore.shared
        
    override func fetchRemoteModels() async throws -> [ActivityDTO] {
        return try await activitiesService.fetchActivities(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: ActivityPayload) async throws -> ActivityDTO {
        return try await activitiesService.createActivity(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: ActivityPayload) async throws -> ActivityDTO {
        return try await activitiesService.updateActivity(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Country deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        
        let allActivities = try modelContext.fetch(FetchDescriptor<Activity>())
        let modelsWithRid = allActivities.filter { $0.rid != nil }
        
        let activityCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) },
                                       uniquingKeysWith: { (first, _) in first })
        
        for activity in allActivities {
            guard let parentRid = activity.parentRid else {
                if activity.parent != nil {
                    activity.parent = nil
                }
                continue
            }
            
            if activity.parent?.rid != parentRid {
                activity.parent = activityCache[parentRid]
            }
        }
    }
    
}

