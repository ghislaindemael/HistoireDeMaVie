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
    Model: SyncableModel & Identifiable & PersistentModel,
    DTO: Codable & Identifiable,
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
    
    // MARK: - Push Logic (Local -> Server)
    
    /// Pushes local creations, updates, and deletions to the server.
    /// Returns a dictionary mapping temporary local IDs to permanent server IDs.
    func pushChanges() async throws -> Void {
        let localItems = try fetchLocalModels(with: SyncStatus.local)
        let failedItems = try fetchLocalModels(with: SyncStatus.failed)
        let itemsToSync = localItems + failedItems
        
        guard !itemsToSync.isEmpty else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for item in itemsToSync {
                group.addTask {
                    guard let payload = Payload(from: item) else {
                        print("Skipping item with UUID: \(item.id)")
                        item.syncStatus = .failed
                        return
                    }
                    
                    do {
                        if item.rid == nil {
                            let newDTO = try await self.createOnServer(payload: payload)
                            item.rid = newDTO.id
                            item.syncStatus = .synced
                        } else {
                            _ = try await self.updateOnServer(rid: item.rid!, payload: payload)
                            item.syncStatus = .synced
                        }
                    } catch {
                        item.syncStatus = .failed
                        print("❌ Failed to sync item \(item.id): \(error)")
                    }
                }
            }
        }
        
        try modelContext.save()
    }
    
    
    // MARK: - Pull Logic (Server -> Local)
    
    func pullChanges() async throws { fatalError("Subclasses must implement")}

    // MARK: - Abstract Methods for Subclasses to Implement
    
    /// This method will be overridden by subclasses to update any children that were pointing to a local parent.
    func createOnServer(payload: Payload) async throws -> DTO { fatalError("Subclasses must implement") }
    func updateOnServer(rid: Int, payload: Payload) async throws -> DTO { fatalError("Subclasses must implement") }
    func deleteFromServer(_ rid: Int) async throws { fatalError("Subclasses must implement") }
    
    // MARK: - Helpers
    
    private func fetchLocalModels(with status: SyncStatus) throws -> [Model] {
        let predicate = #Predicate<Model> { $0.syncStatusRaw == status.rawValue }
        return try modelContext.fetch(FetchDescriptor(predicate: predicate))
    }
    
    
}
