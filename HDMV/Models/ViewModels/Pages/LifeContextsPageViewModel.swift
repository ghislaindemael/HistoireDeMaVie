//
//  LifeContextsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation
import SwiftData

@MainActor
class LifeContextsPageViewModel: BasePageViewModel {
    
    private var lifeContextSyncer: LifeContextSyncer?
    
    @Published var contexts: [LifeContext] = []
    
    // MARK: - Computed Properties for Views
    var hasLocalChanges: Bool {
        return contexts.contains(where: { $0.hasUnsyncedChanges })
    }
    
    // MARK: Initialization
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lifeContextSyncer = LifeContextSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let predicate = #Predicate<LifeContext> { $0.parentRid == nil }
            
            let descriptor = FetchDescriptor<LifeContext>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.name)]
            )
            
            self.contexts = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = lifeContextSyncer else { return }
        do {
            try await syncer.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = lifeContextSyncer else { return }
        do {
            _ = try await syncer.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    // MARK: User Actions
    
    func createContext() {
        guard let context = modelContext else { return }
        let newContext = LifeContext.create(in: context)
        contexts.append(newContext)
    }
}
