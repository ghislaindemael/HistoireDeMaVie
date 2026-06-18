//
//  CountriesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import Foundation
import SwiftData

@MainActor
class CountriesPageViewModel: BasePageViewModel {
    
    var syncer: AnySyncer?
    var sortDescriptors: [SortDescriptor<Country>] = [SortDescriptor(\.slug)]
    
    @Published var items: [Country] = []
    
    // MARK: Initialization
            
    override func setup(modelContext: ModelContext) {
        super.setup(modelContext: modelContext)
        self.syncer = CountrySyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    func fetchFromCache() {
        self.items = super.fetchFromCache(sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Sync & Data Lifecycle
    
    func refreshFromServer() async {
        self.items = await super.refreshFromServer(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func uploadLocalChanges() async {
        self.items = await super.uploadLocalChanges(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func fetchArchivedFromServer() async {
        self.items = await super.fetchArchivedFromServer(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func purgeArchivedFromCache() {
        self.items = super.purgeArchivedFromCache(sortDescriptors: sortDescriptors)
    }
    
    func deleteItem(_ item: Country) {
        self.items = super.deleteItem(item, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - User Actions
            
    func createCountry() {
        if let items = super.createPlaceholderIfNeeded(factory: { Country(syncStatus: .unsynced) }, sortDescriptors: sortDescriptors) {
            self.items = items
        }
    }
}

