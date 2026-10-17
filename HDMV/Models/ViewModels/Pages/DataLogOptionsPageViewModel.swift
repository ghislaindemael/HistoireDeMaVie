//
//  DataLogOptionsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@MainActor
class DataLogOptionsPageViewModel: BasePageViewModel {
    
    private var optionSyncer: DataLogOptionSyncer?
    private var mappingSyncer: DataLogOptionMappingSyncer?
    
    @Published var options: [DataLogOption] = []
    
    var hasLocalChanges: Bool {
        return options.contains(where: { $0.hasUnsyncedChanges })
    }
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.optionSyncer = DataLogOptionSyncer(modelContext: modelContext)
        self.mappingSyncer = DataLogOptionMappingSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DataLogOption>(
                sortBy: [SortDescriptor(\.slug)]
            )
            self.options = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch options from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        if let syncer = optionSyncer {
            do {
                try await syncer.pullChanges()
            } catch {
                print("Failed to pull options: \(error)")
            }
        }
        if let mappingSyncer = mappingSyncer {
            do {
                try await mappingSyncer.pullChanges()
            } catch {
                print("Failed to pull option mappings: \(error)")
            }
        }
        fetchFromCache()
    }
    
    func fetchArchivedFromServer() async {
        await executeFetchArchived(refreshAction: refreshFromServer)
    }
    
    func purgeArchivedFromCache() {
        executePurgeArchived(type: DataLogOption.self, context: modelContext, fetchAction: fetchFromCache)
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        if let syncer = optionSyncer {
            do {
                try await syncer.pushChanges()
            } catch {
                print("Failed to push options: \(error)")
            }
        }
        if let mappingSyncer = mappingSyncer {
            do {
                try await mappingSyncer.pushChanges()
            } catch {
                print("Failed to push option mappings: \(error)")
            }
        }
        fetchFromCache()
    }
    
    @discardableResult
    func createOption() -> DataLogOption? {
        guard let context = modelContext else { return nil }
        
        // Enforce unique slug: only a single unset option can exist at any time
        let descriptor = FetchDescriptor<DataLogOption>()
        if let all = try? context.fetch(descriptor),
           let existingUnset = all.first(where: { !$0.isValid() || $0.slug == "!unset" || $0.slug.hasPrefix("!") }) {
            print("⚠️ An unset DataLogOption already exists (\(existingUnset.slug)). Configure it first!")
            return existingUnset
        }
        
        let newOption = DataLogOption(syncStatus: .unsynced)
        context.insert(newOption)
        options.insert(newOption, at: 0)
        do {
            try context.save()
            return newOption
        } catch {
            print("Failed to create Option: \(error)")
            return nil
        }
    }
    
    func deleteOption(_ option: DataLogOption) {
        guard let context = modelContext else { return }
        context.delete(option)
        options.removeAll { $0.id == option.id }
        do {
            try context.save()
        } catch {
            print("Failed to delete Option: \(error)")
        }
    }
}
