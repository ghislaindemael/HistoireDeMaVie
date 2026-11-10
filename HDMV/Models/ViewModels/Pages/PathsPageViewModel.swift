//
//  PathsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData

@MainActor
class PathsPageViewModel: BasePageViewModel {
    
    var syncer: AnySyncer?
    var sortDescriptors: [SortDescriptor<Path>] = [SortDescriptor(\.name)]
    
    @Published var paths: [Path] = []
    
    override func setup(modelContext: ModelContext) {
        super.setup(modelContext: modelContext)
        self.syncer = PathSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    func fetchFromCache() {
        self.paths = super.fetchFromCache(sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Sync & Data Lifecycle
    
    func refreshFromServer() async {
        self.paths = await super.refreshFromServer(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func uploadLocalChanges() async {
        self.paths = await super.uploadLocalChanges(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func fetchArchivedFromServer() async {
        self.paths = await super.fetchArchivedFromServer(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func purgeArchivedFromCache() {
        self.paths = super.purgeArchivedFromCache(sortDescriptors: sortDescriptors)
    }
    
    func deleteItem(_ item: Path) {
        self.paths = super.deleteItem(item, sortDescriptors: sortDescriptors)
    }
    
    func createLocalPath() {
        if let updated = super.createPlaceholderIfNeeded(
            factory: { Path(syncStatus: .unsynced) },
            sortDescriptors: sortDescriptors
        ) {
            self.paths = updated
        }
    }
}
