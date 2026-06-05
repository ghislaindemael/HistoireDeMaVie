//
//  DataActivityOptionsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@MainActor
class DataActivityOptionsPageViewModel: BasePageViewModel {
    
    private var optionSyncer: DataActivityOptionSyncer?
    
    @Published var options: [DataActivityOption] = []
    
    var hasLocalChanges: Bool {
        return options.contains(where: { $0.hasUnsyncedChanges })
    }
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.optionSyncer = DataActivityOptionSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DataActivityOption>(
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
            fetchFromCache()
        } catch {
            print("Failed to refresh options from server: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = optionSyncer else { return }
        do {
            _ = try await syncer.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to push options to server: \(error)")
        }
    }
    
    func createOption() {
        guard let context = modelContext else { return }
        let newOption = DataActivityOption(syncStatus: .unsynced)
        
        context.insert(newOption)
        options.append(newOption)
        do {
            try context.save()
        } catch {
            print("Failed to create Option: \(error)")
        }
    }
}
