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
        
        let localModels = try modelContext.fetch(FetchDescriptor<Model>())
        let modelsWithRid = localModels.filter { $0.rid != nil }
        
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in
            return first
        })
        let localRids = Set(localCache.keys)
        
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else {
                    continue
                }
                existingModel.update(fromDto: dto)
            } else {
                let newModel = Model(fromDto: dto)
                modelContext.insert(newModel)
            }
        }
        
        let ridsToDelete = localRids.subtracting(serverRids)
        for rid in ridsToDelete {
            if let modelToDelete = localCache[rid] {
                
                if modelToDelete.syncStatus == .synced {
                    modelContext.delete(modelToDelete)
                }
            }
        }
        do {
            try resolveRelationships()
            try modelContext.save()
            print("✅ Context saved successfully in pullChanges.")
        } catch {
            print("‼️ FAILED to save context in pullChanges: \(error)")
        }
    }
    
    func pullChanges(for date: Date? = nil) async throws {
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
