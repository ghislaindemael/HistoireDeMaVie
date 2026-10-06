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
                sortBy: [SortDescriptor(\.name)]
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
    
    func createOption() {
        guard let context = modelContext else { return }
        let newOption = DataLogOption(syncStatus: .unsynced)
        
        context.insert(newOption)
        options.append(newOption)
        do {
            try context.save()
        } catch {
            print("Failed to create Option: \(error)")
        }
    }
}
