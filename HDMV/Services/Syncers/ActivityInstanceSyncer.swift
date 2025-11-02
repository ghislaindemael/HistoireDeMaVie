//
//  ActivityInstanceSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData

@MainActor
class ActivityInstanceSyncer: BaseLogSyncer<ActivityInstance, ActivityInstanceDTO, ActivityInstancePayload> {
    
    private let instanceService = ActivityInstanceService()

    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date?) async throws -> [ActivityInstanceDTO] {
        guard let filterDate = date else {
            print("❌ Error: Date must be provided when fetching ActivityInstances.")
            throw SyncError.missingDateContext
        }
        return try await instanceService.fetchActivityInstances(for: filterDate)
    }
        
    override func createOnServer(payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        return try await instanceService.createActivityInstance(payload)
    }
    
    override func updateOnServer(rid: Int, payload: ActivityInstancePayload) async throws -> ActivityInstanceDTO {
        return try await instanceService.updateActivityInstance(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        //try await instanceService.deleteActivityInstance(id: id)
    }
        
    override func resolveRelationships(for syncedInstance: ActivityInstance) throws {
        guard let newParentRid = syncedInstance.rid else { return }

        let targetParentID = syncedInstance.id            
        let parentRelationshipPredicate = #Predicate<ActivityInstance> { child in
            child.parent?.id == targetParentID
        }
        
        let parentRidPredicate = #Predicate<ActivityInstance> { child in
            child.parentRid == nil || child.parentRid != newParentRid
        }
        
        let combinedPredicate = #Predicate<ActivityInstance> { child in
            parentRelationshipPredicate.evaluate(child) &&
            parentRidPredicate.evaluate(child)
        }
        let descriptor = FetchDescriptor<ActivityInstance>(predicate: combinedPredicate)
        let childrenToFix = try modelContext.fetch(descriptor)
        
        if !childrenToFix.isEmpty {
            print("Resolving child parentRids for ActivityInstance rid: \(newParentRid)...")
        }
        
        for child in childrenToFix {
            print("  -> Fixing stale parentRid for child instance \(child.id)")
            child.parentRid = newParentRid
            
            if child.syncStatus == .synced {
                print("  -> Marking child \(child.id) as .local to push parentRid update.")
                child.markAsModified()
            }
        }
    }
    
    override func pullChanges(date: Date?) async throws {
        guard let filterDate = date else { throw SyncError.missingDateContext }
        
        let dtos = try await instanceService.fetchActivityInstances(for: filterDate)
        let serverRids = Set(dtos.map { $0.id })
        
        let (startOfDay, endOfDay) = getDayBounds(for: filterDate)
        let future = Date.distantFuture
        let predicate = #Predicate<ActivityInstance> {
            $0.timeStart < endOfDay && ($0.timeEnd ?? future) > startOfDay
        }
        let descriptor = FetchDescriptor<ActivityInstance>(predicate: predicate)
        let relevantLocalModels = try modelContext.fetch(descriptor)
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
            } else {
                let newModel = ActivityInstance(fromDto: dto)
                modelContext.insert(newModel)
            }
        }
        
        let ridsToDelete = localRids.subtracting(serverRids)
        for rid in ridsToDelete {
            if let modelToDelete = localCache[rid], modelToDelete.syncStatus == .synced {
                modelContext.delete(modelToDelete)
            }
        }
        
        try resolveRelationships()
        if modelContext.hasChanges { try modelContext.save() }
    }
    
    func pullChanges(activityRid: Int, startDate: Date, endDate: Date) async throws {
        
        let dtos = try await instanceService.fetchActivityInstances(
            activityId: activityRid,
            startDate: startDate,
            endDate: endDate
        )
        let serverRids = Set(dtos.map { $0.id })
        
        let (startOfDay, endOfDay) = getDayBounds(for: startDate, and: endDate)
        let future = Date.distantFuture
        let predicate = #Predicate<ActivityInstance> { model in
            model.activityRid == activityRid &&
            model.timeStart < endOfDay &&
            (model.timeEnd ?? future) > startOfDay
        }
        let descriptor = FetchDescriptor<ActivityInstance>(predicate: predicate)
        let relevantLocalModels = try modelContext.fetch(descriptor)
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
            } else {
                let newModel = ActivityInstance(fromDto: dto)
                modelContext.insert(newModel)
            }
        }
        
        let ridsToDelete = localRids.subtracting(serverRids)
        for rid in ridsToDelete {
            if let modelToDelete = localCache[rid], modelToDelete.syncStatus == .synced {
                modelContext.delete(modelToDelete)
            }
        }
        
        try resolveRelationships()
        if modelContext.hasChanges { try modelContext.save() }
    }
    
    private func getDayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
    
    private func getDayBounds(for start: Date, and end: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: start)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end))!
        return (startOfDay, endOfDay)
    }
    
    
    
}
