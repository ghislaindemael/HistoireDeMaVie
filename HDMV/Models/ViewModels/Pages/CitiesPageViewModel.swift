//
//  CitiesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation
import SwiftData

@MainActor
class CitiesPageViewModel: BasePageViewModel {
    
    var syncer: AnySyncer?
    var sortDescriptors: [SortDescriptor<City>] = [SortDescriptor(\.slug)]
    
    @Published var items: [City] = []
    @Published var selectedCountry: Country?
    
    // MARK: Initialization
            
    override func setup(modelContext: ModelContext) {
        super.setup(modelContext: modelContext)
        self.syncer = CitySyncer(modelContext: modelContext)
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
    
    func deleteItem(_ item: City) {
        self.items = super.deleteItem(item, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - User Actions
            
    func createCity() {
        if let items = super.createPlaceholderIfNeeded(factory: { 
            let city = City(syncStatus: .unsynced)
            city.setCountry(selectedCountry)
            return city
        }, sortDescriptors: sortDescriptors) {
            self.items = items
        }
    }
}
