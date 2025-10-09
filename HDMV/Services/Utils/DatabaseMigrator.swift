//
//  DatabaseMigrator.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import SwiftData

@MainActor
enum DatabaseMigrator {
    
    /// Generic migration for any model conforming to SyncableModel
    static func migrateSyncStatus<T: SyncableModel>(for type: T.Type, in context: ModelContext) throws {
        let objects = try context.fetch(FetchDescriptor<T>())
        var updated = 0
        
        for obj in objects {
            if obj.id > 0 && obj.syncStatusRaw == SyncStatus.undef.rawValue {
                obj.syncStatusRaw = SyncStatus.synced.rawValue
                updated += 1
            }
        }
        
        if updated > 0 {
            try context.save()
            print("✅ Migrated \(updated) objects for \(T.self) to .synced")
        }
    }
    
    /// Run migration for all models
    static func migrateAllSyncableModels(container: ModelContainer) throws {
        let context = ModelContext(container)
        
        do {
            try migrateSyncStatus(for: Activity.self, in: context)
            try migrateSyncStatus(for: ActivityInstance.self, in: context)
            try migrateSyncStatus(for: TripLeg.self, in: context)
            try migrateSyncStatus(for: Path.self, in: context)
            try migrateSyncStatus(for: PersonInteraction.self, in: context)
        } catch {
            print("❌ Migration failed: \(error)")
        }
    }
}
