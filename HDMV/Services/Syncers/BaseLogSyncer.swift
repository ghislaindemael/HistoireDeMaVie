//
//  BaseLogSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 02.11.2025.
//


import Foundation
import SwiftData

@MainActor
class BaseLogSyncer<Model, DTO, Payload>: BaseSyncer<Model, DTO, Payload>
where
    Model: SyncableModel & Identifiable & PersistentModel & TimeBound,
    DTO: Codable & Identifiable,
    DTO == Model.DTO,
    DTO.ID == Int,
    Payload: Codable & InitializableWithModel,
    Payload.Model == Model
{

    override func pullChanges(date: Date?) async throws {
        guard let filterDate = date else {
            print("❌ Error: \(Model.self) Syncer requires a date to pull changes.")
            throw SyncError.missingDateContext
        }
        
        let dtos = try await fetchRemoteModels(date: filterDate)
        let serverRids = Set(dtos.map { $0.id })
        print("PullChanges (\(Model.self)): Found \(dtos.count) DTOs from server.")

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: filterDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw SyncError.dateCalculationError
        }
        let future = Date.distantFuture

        let predicate = #Predicate<Model> { model in
            model.timeStart < endOfDay && (model.timeEnd ?? future) > startOfDay
        }
        let descriptor = FetchDescriptor<Model>(predicate: predicate)
        let relevantLocalModels = try modelContext.fetch(descriptor)
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        print("PullChanges (\(Model.self)): Found \(relevantLocalModels.count) relevant local models.")

        var insertedCount = 0
        var updatedCount = 0
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
                updatedCount += 1
            } else {
                let newModel = Model(fromDto: dto)
                modelContext.insert(newModel)
                insertedCount += 1
            }
        }
        print("PullChanges (\(Model.self)): Inserted \(insertedCount), Updated \(updatedCount).")

        let ridsToDelete = localRids.subtracting(serverRids)
        var deletedCount = 0
        if !ridsToDelete.isEmpty {
            print("PullChanges: Pruning \(ridsToDelete.count) items for \(Model.self)...")
            for rid in ridsToDelete {
                if let modelToDelete = localCache[rid] {
                    if modelToDelete.syncStatus == .synced {
                        modelContext.delete(modelToDelete)
                        deletedCount += 1
                    } else {
                        print("   - Skipping prune for \(modelToDelete.id) (status: \(modelToDelete.syncStatus))")
                    }
                }
            }
            print("PullChanges: Deleted \(deletedCount) items for \(Model.self).")
        }
        
        try resolveRelationships()
        if modelContext.hasChanges {
            try modelContext.save()
            print("✅ Context saved successfully in pullChanges for \(Model.self).")
        } else {
             print("PullChanges: No changes to save for \(Model.self).")
        }
    }
}
