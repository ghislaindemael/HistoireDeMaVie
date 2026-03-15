//
//  TransactionTypesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//

import Foundation
import SwiftData

@MainActor
class TransactionTypesPageViewModel: BasePageViewModel {
    
    private var transactionTypesSyncer: TransactionTypesSyncer?
    
    @Published var transactionTypes: [TransactionType] = []
    
    // MARK: - Computed Properties for Views
    var hasLocalChanges: Bool {
        return transactionTypes.contains(where: { $0.hasUnsyncedChanges })
    }
    
    // MARK: Initialization
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.transactionTypesSyncer = TransactionTypesSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let predicate = #Predicate<TransactionType> { $0.parent == nil }
            
            let descriptor = FetchDescriptor<TransactionType>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.name)]
            )
            
            self.transactionTypes = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = transactionTypesSyncer else {
            print("⚠️ [TransactionTypesPageViewModel] Syncer is nil")
            return
        }
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
        guard let syncer = transactionTypesSyncer else {
            print("⚠️ [TransactionTypesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    
    // MARK: User Actions
    
    func createTransactionType() {
        guard let context = modelContext else { return }
        let newType = TransactionType(syncStatus: .unsynced)
        
        context.insert(newType)
        transactionTypes.append(newType)
        do {
            try context.save()
        } catch {
            print("Failed to create Transaction Type: \(error)")
        }
    }
    
}
