//
//  VaultTaskSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.03.2026.
//

import Foundation
import SwiftData

@MainActor
class VaultTaskSyncer: BaseSyncer<VaultTask, VaultTaskDTO, VaultTaskPayload> {
    
    private let taskService = VaultTaskService()
    
    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date? = nil) async throws -> [VaultTaskDTO] {
        var dtos = try await taskService.fetchAllPendingTasks()
        
        if let filterDate = date {
            let dateDTOs = try await taskService.fetchTasks(for: filterDate)
            
            let existingIDs = Set(dtos.map { $0.id })
            for dto in dateDTOs where !existingIDs.contains(dto.id) {
                dtos.append(dto)
            }
        }
        
        return dtos
    }
    
    override func createOnServer(payload: VaultTaskPayload) async throws -> VaultTaskDTO {
        return try await taskService.createTask(payload)
    }
    
    override func updateOnServer(rid: Int, payload: VaultTaskPayload) async throws -> VaultTaskDTO {
        return try await taskService.updateTask(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await taskService.deleteTask(id: id)
    }
    
    // MARK: - Custom Pull Logic (State + Date)
    
    override func pullChanges(date: Date? = nil) async throws {
        print("Pulling VaultTasks...")
        let dtos = try await fetchRemoteModels(date: date)
        let serverRids = Set(dtos.map { $0.id })
        
        let allLocalModels = try modelContext.fetch(FetchDescriptor<VaultTask>())
        let relevantLocalModels = allLocalModels.filter { task in
            let isPending = task.status == .todo || task.status == .inProgress
            
            var matchesDate = false
            if let fDate = date {
                let (start, end) = getDayBounds(for: fDate)
                let tStart = task.timeStart ?? .distantPast
                let tEnd = task.timeEnd ?? .distantFuture
                matchesDate = tStart < end && tEnd > start
            }
            
            return isPending || matchesDate
        }
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        
        var inserted = 0, updated = 0
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
                updated += 1
            } else {
                let newModel = VaultTask(fromDto: dto)
                modelContext.insert(newModel)
                inserted += 1
            }
        }
        
        // Prune Local Cache
        let ridsToDelete = localRids.subtracting(serverRids)
        var deleted = 0
        for rid in ridsToDelete {
            if let modelToDelete = localCache[rid], modelToDelete.syncStatus == .synced {
                modelContext.delete(modelToDelete)
                deleted += 1
            }
        }
        
        print("VaultTasks Sync Complete: Inserted \(inserted), Updated \(updated), Pruned \(deleted)")
        
        try resolveRelationships()
        if modelContext.hasChanges { try modelContext.save() }
    }
    
    // MARK: - Relationship Resolution
    
    override func resolveRelationships() throws {
        print("Resolving VaultTask relationships...")
        
        // let taskLookup: [Int: VaultTask] = try getLookupMap()
        /*
         try resolveRelationship(
         for: VaultTask.self,
         relationshipKeyPath: \VaultTask.parentTask,
         ridKeyPath: \VaultTask.parentTaskRid,
         lookupMap: taskLookup
         )
         */
        
        print("All VaultTask relationships resolved.")
    }
    
    // MARK: - Helpers
    private func getDayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
