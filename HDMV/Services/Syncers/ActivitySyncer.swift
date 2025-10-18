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
    
}

