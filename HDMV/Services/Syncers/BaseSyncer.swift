//
//  BaseSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


// BaseSyncer.swift (New File)
import Foundation
import SwiftData


/// An abstract base class for syncing a specific SwiftData model with a remote server.
@MainActor
class BaseSyncer<Model, DTO, Payload>
where
    Model:SyncableModel & PersistentModel,
    DTO: Codable & Identifiable,
    Payload: Codable & InitializableWithModel,
    Model.ID == Int,
    DTO.ID == Int,
    Payload.Model == Model
{
    
    private enum SyncTaskResult {
        case created(tempId: Int, newDTO: DTO)
        case updated(id: Int)
        case failed(id: Int, error: Error)
        case skipped(id: Int)
    }
    
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// The main entry point for a full two-way sync.
    final func sync() async throws {
        let idMap = try await pushChanges()
        try await updateChildrenWithNewParentIDs(idMap)
        try await pullChanges()
    }
    
    // MARK: - Push Logic (Local -> Server)
    
    /// Pushes local creations, updates, and deletions to the server.
    /// Returns a dictionary mapping temporary local IDs to permanent server IDs.
    func pushChanges() async throws -> [Int: Int] {
        let localItems = try fetchLocalModels(with: SyncStatus.local)
        let failedItems = try fetchLocalModels(with: SyncStatus.failed)
        let itemsToSync = localItems + failedItems
        
        guard !itemsToSync.isEmpty else {
            return [:]
        }
        
        let taskResults = await withTaskGroup(of: SyncTaskResult.self, returning: [SyncTaskResult].self) { group in
            for item in itemsToSync {
                group.addTask {
                    guard let payload = Payload(from: item) else {
                        return .skipped(id: item.id)
                    }
                    
                    do {
                        if item.id < 0 {
                            let newDTO = try await self.createOnServer(payload: payload)
                            return .created(tempId: item.id, newDTO: newDTO)
                        } else {
                            _ = try await self.updateOnServer(id: item.id, payload: payload)
                            return .updated(id: item.id)
                        }
                    } catch {
                        return .failed(id: item.id, error: error)
                    }
                }
            }
            
            var results: [SyncTaskResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        var temporaryToPermanentIdMap = [Int: Int]()
        
        let itemsDict = Dictionary(uniqueKeysWithValues: itemsToSync.map { ($0.id, $0) })
        
        for result in taskResults {
            switch result {
                case .created(let tempId, let newDTO):
                    if let item = itemsDict[tempId] {
                        item.id = newDTO.id
                        item.syncStatus = .synced
                        temporaryToPermanentIdMap[tempId] = newDTO.id
                    }
                    
                case .updated(let id):
                    if let item = itemsDict[id] {
                        item.syncStatus = .synced
                    }
                    
                case .failed(let id, let error):
                    if let item = itemsDict[id] {
                        item.syncStatus = .failed
                    }
                    print("❌ Failed to sync item \(id): \(error)")
                    
                case .skipped(let id):
                    print("- Skipped syncing invalid item \(id)")
            }
        }
        
        try modelContext.save()
        return temporaryToPermanentIdMap
    }
    
    
    // MARK: - Pull Logic (Server -> Local)
    
    func pullChanges() async throws {
        // Implement your 'pull' logic in subclasses
    }
    
    // MARK: - Abstract Methods for Subclasses to Implement
    
    /// This method will be overridden by subclasses to update any children
    /// that were pointing to a temporary parent ID.
    func updateChildrenWithNewParentIDs(_ idMap: [Int: Int]) async throws {
        // Default implementation does nothing.
    }
    
    func createOnServer(payload: Payload) async throws -> DTO { fatalError("Subclasses must implement") }
    func updateOnServer(id: Model.ID, payload: Payload) async throws -> DTO { fatalError("Subclasses must implement") }
    func deleteFromServer(_ id: Model.ID) async throws { fatalError("Subclasses must implement") }
    
    // MARK: - Helpers
    
    private func fetchLocalModels(with status: SyncStatus) throws -> [Model] {
        let predicate = #Predicate<Model> { $0.syncStatusRaw == status.rawValue }
        return try modelContext.fetch(FetchDescriptor(predicate: predicate))
    }
    
    
}
