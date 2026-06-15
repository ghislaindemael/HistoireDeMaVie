//
//  DataMediaItemsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation
import SwiftData

@MainActor
class DataMediaItemsPageViewModel: BasePageViewModel {
    
    private var itemSyncer: DataMediaItemSyncer?
    
    @Published var items: [DataMediaItem] = []
    
    // MARK: - Computed Properties for Views
    var hasLocalChanges: Bool {
        return items.contains(where: { $0.hasUnsyncedChanges })
    }
    
    // MARK: Initialization
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.itemSyncer = DataMediaItemSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let predicate = #Predicate<DataMediaItem> { $0.parentRid == nil }
            
            let descriptor = FetchDescriptor<DataMediaItem>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.name)]
            )
            
            self.items = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = itemSyncer else { return }
        do {
            try await syncer.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func fetchArchivedFromServer() async {
        await executeFetchArchived(refreshAction: refreshFromServer)
    }
    
    func purgeArchivedFromCache() {
        executePurgeArchived(type: DataMediaItem.self, context: modelContext, fetchAction: fetchFromCache)
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = itemSyncer else { return }
        do {
            _ = try await syncer.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to upload data to server: \(error)")
        }
    }
    
    // MARK: User Actions
    
    func createItem() {
        guard let context = modelContext else { return }
        let newItem = DataMediaItem.create(in: context)
        items.append(newItem)
    }
}
