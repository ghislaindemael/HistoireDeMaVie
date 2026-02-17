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
}
