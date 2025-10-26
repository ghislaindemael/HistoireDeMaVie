//
//  BaseSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


// BaseSyncer.swift
import Foundation
import SwiftData


/// An abstract base class for syncing a specific SwiftData model with a remote server.
@MainActor
class BaseSyncer<Model, DTO, Payload>
where
    Model: SyncableModel & Identifiable & PersistentModel,
    DTO: Codable & Identifiable,
    DTO == Model.DTO,
    DTO.ID == Int,
    Payload: Codable & InitializableWithModel,
    Payload.Model == Model
{
    
    private enum SyncTaskResult {
        case created(id: PersistentIdentifier, newDTO: DTO)
        case updated(id: PersistentIdentifier)
        case failed(id: PersistentIdentifier, error: Error)
        case skipped(id: PersistentIdentifier)
    }
    
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// The main entry point for a full two-way sync.
    final func sync() async throws {
        try await pushChanges()
        try await pullChanges()
    }
    
    // MARK: - Sync Logic
    
    /// Pushes local creations, updates, and deletions to the server.
    func pushChanges() async throws {
        let localItems = try fetchLocalModels(with: SyncStatus.local)
        let failedItems = try fetchLocalModels(with: SyncStatus.failed)
        let itemsToSync = localItems + failedItems
        
        guard !itemsToSync.isEmpty else { return }
        
        for item in itemsToSync {
            guard let payload = Payload(from: item) else {
                print("Invalid payload for: \(item.id)")
                continue
            }
            
            do {
                if item.rid == nil {
                    let newDTO = try await self.createOnServer(payload: payload)
                    item.rid = newDTO.id
                    item.syncStatus = .synced
                    try self.resolveRelationships(for: item)
                    
                } else {
                    _ = try await self.updateOnServer(rid: item.rid!, payload: payload)
                    item.syncStatus = .synced
                }
            } catch {
                item.syncStatus = .failed
                print("❌ Failed to sync item \(item.id): \(error)")
            }
        }
        try modelContext.save()
    }
    
    @MainActor
    func defaultPullChanges(date: Date? = nil) async throws {
        let dtos = try await fetchRemoteModels(date: date)
        let serverRids = Set(dtos.map { $0.id })
        
        let allLocalModels = try modelContext.fetch(FetchDescriptor<Model>())
        
        let relevantLocalModels: [Model]
        if let filterDate = date, Model.self is any TimeTrackable.Type {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: filterDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw SyncError.dateCalculationError
            }
            let future = Date.distantFuture
            
            relevantLocalModels = allLocalModels.filter { model in
                if let timeTrackableModel = model as? any TimeTrackable {
                    return timeTrackableModel.timeStart < endOfDay &&
                    (timeTrackableModel.timeEnd ?? future) > startOfDay
                }
                return false
            }
        } else {
            relevantLocalModels = allLocalModels
        }
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        print("PullChanges: Found \(relevantLocalModels.count) relevant local models (\(localRids.count) with rids) for \(Model.self).")
        
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
        print("PullChanges: Inserted \(insertedCount), Updated \(updatedCount) for \(Model.self).")
        
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
        
        do {
            try resolveRelationships()
        } catch {
            print("‼️ FAILED during resolveRelationships in pullChanges: \(error)")
        }
        
        
        if modelContext.hasChanges {
            do {
                try modelContext.save()
                print("✅ Context saved successfully in pullChanges for \(Model.self).")
            } catch {
                print("‼️ FAILED to save context in pullChanges for \(Model.self): \(error)")
                throw error
            }
        } else {
            print("PullChanges: No changes to save for \(Model.self).")
        }
    }
    
    func pullChanges(date: Date? = nil) async throws {
        try await defaultPullChanges(date: date)
    }
    

    // MARK: - Abstract Methods for Subclasses to Implement
    
    func fetchRemoteModels(date: Date? = nil) async throws -> [DTO] { fatalError("Subclasses must implement fetchRemoteModels()") }
    func createOnServer(payload: Payload) async throws -> DTO { fatalError("Subclasses must implement") }
    func updateOnServer(rid: Int, payload: Payload) async throws -> DTO { fatalError("Subclasses must implement") }
    func deleteFromServer(_ rid: Int) async throws { fatalError("Subclasses must implement") }
    func resolveRelationships() throws {}
    func resolveRelationships(for model: Model) throws {}
    // MARK: - Helpers
    
    
    
    private func fetchLocalModels(with status: SyncStatus) throws -> [Model] {
        let predicate = #Predicate<Model> { $0.syncStatusRaw == status.rawValue }
        return try modelContext.fetch(FetchDescriptor(predicate: predicate))
    }
    
    
}
