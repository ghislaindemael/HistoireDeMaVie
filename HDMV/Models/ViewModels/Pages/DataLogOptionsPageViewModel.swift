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
        guard let syncer = optionSyncer else { return }
        do {
            try await syncer.pullChanges()
            if let mappingSyncer = mappingSyncer {
                try await mappingSyncer.pullChanges()
            }
            fetchFromCache()
        } catch {
            print("Failed to refresh options from server: \(error)")
        }
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
        guard let syncer = optionSyncer else { return }
        do {
            _ = try await syncer.pushChanges()
            if let mappingSyncer = mappingSyncer {
                _ = try await mappingSyncer.pushChanges()
            }
            fetchFromCache()
        } catch {
            print("Failed to push options to server: \(error)")
        }
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
