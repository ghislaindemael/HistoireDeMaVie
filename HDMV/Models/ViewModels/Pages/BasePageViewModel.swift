//
//  BasePageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import SwiftUI
import SwiftData

@MainActor
class BasePageViewModel: ObservableObject {
    var modelContext: ModelContext?
    @Published var isLoading = false

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// The "Magic Fix" for iOS 26 mutation
    func updateModel<T: CachableObject>(_ model: T, mutation: (T) -> Void) {
        // Since we are inside a class, we can mutate the reference freely
        mutation(model)
        
        /* Disabling markAsModified to prevent non-useful syncs
        // Mark for sync if your models support it
        if let syncable = model as? any SyncableModel {
            syncable.markAsModified()
        }
        */

        save()
    }

    func save() {
        guard let context = modelContext, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("❌ BasePageViewModel: Failed to save: \(error)")
        }
    }
    
    // MARK: - Archive Utilities
    
    func executeFetchArchived(refreshAction: () async -> Void) async {
        SettingsStore.shared.includeArchived = true
        defer { SettingsStore.shared.includeArchived = false }
        
        await refreshAction()
    }
    
    func executePurgeArchived<T: PersistentModel & CachableModel>(
        type: T.Type,
        context: ModelContext?,
        fetchAction: () -> Void
    ) {
        guard let context = context else { return }
        
        do {
            let predicate = #Predicate<T> { $0.archived == true }
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let archivedItems = try context.fetch(descriptor)
            
            for item in archivedItems {
                context.delete(item)
            }
            save()
            fetchAction()
        } catch {
            print("Failed to purge archived items: \(error)")
        }
    }

    // MARK: - Generic Catalogue Methods
    
    func fetchFromCache<Model: PersistentModel>(
        sortDescriptors: [SortDescriptor<Model>]
    ) -> [Model] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Model>(sortBy: sortDescriptors)
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch \(Model.self): \(error)")
            return []
        }
    }
    
    func refreshFromServer<Model: PersistentModel & SyncableModel>(
        syncer: AnySyncer?,
        sortDescriptors: [SortDescriptor<Model>]
    ) async -> [Model] {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = syncer else { return fetchFromCache(sortDescriptors: sortDescriptors) }
        do {
            try await syncer.pullChanges(date: nil)
        } catch {
            print("Failed to refresh \(Model.self): \(error)")
        }
        return fetchFromCache(sortDescriptors: sortDescriptors)
    }
    
    func uploadLocalChanges<Model: PersistentModel & SyncableModel>(
        syncer: AnySyncer?,
        sortDescriptors: [SortDescriptor<Model>]
    ) async -> [Model] {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = syncer else { return fetchFromCache(sortDescriptors: sortDescriptors) }
        do {
            try await syncer.pushChanges()
        } catch {
            print("Failed to push \(Model.self): \(error)")
        }
        return fetchFromCache(sortDescriptors: sortDescriptors)
    }
    
    func fetchArchivedFromServer<Model: PersistentModel & SyncableModel>(
        syncer: AnySyncer?,
        sortDescriptors: [SortDescriptor<Model>]
    ) async -> [Model] {
        SettingsStore.shared.includeArchived = true
        defer { SettingsStore.shared.includeArchived = false }
        return await refreshFromServer(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func purgeArchivedFromCache<Model: PersistentModel & SyncableModel>(
        sortDescriptors: [SortDescriptor<Model>]
    ) -> [Model] {
        guard let context = modelContext else { return [] }
        do {
            let allItems = try context.fetch(FetchDescriptor<Model>())
            for item in allItems {
                if let cachable = item as? any CachableModel, cachable.archived {
                    context.delete(item)
                }
            }
            save()
        } catch {
            print("Failed to purge archived \(Model.self): \(error)")
        }
        return fetchFromCache(sortDescriptors: sortDescriptors)
    }
    
    func createPlaceholderIfNeeded<Model: PersistentModel & SyncableModel>(
        factory: () -> Model,
        sortDescriptors: [SortDescriptor<Model>]
    ) -> [Model]? {
        guard let context = modelContext else { return nil }
        let fetchedItems = try? context.fetch(FetchDescriptor<Model>())
        if fetchedItems?.contains(where: { !$0.isValid() }) == true {
            print("⚠️ Placeholder \(Model.self) already exists. Finish it first!")
            return nil
        }
        let newItem = factory()
        context.insert(newItem)
        save()
        return fetchFromCache(sortDescriptors: sortDescriptors)
    }
    
    func deleteItem<Model: PersistentModel & SyncableModel>(
        _ item: Model,
        sortDescriptors: [SortDescriptor<Model>]
    ) -> [Model] {
        guard let context = modelContext else { return [] }
        context.delete(item)
        save()
        return fetchFromCache(sortDescriptors: sortDescriptors)
    }
}
