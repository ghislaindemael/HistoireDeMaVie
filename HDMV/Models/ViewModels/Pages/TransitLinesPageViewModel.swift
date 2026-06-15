//
//  TransitLinesPageViewModel.swift
//  HDMV
//

import Foundation
import SwiftData

@MainActor
class TransitLinesPageViewModel: BasePageViewModel {
    
    private var lineSyncer: TransitLineSyncer?
    private var stationSyncer: TransitStationSyncer?
    private var stopSyncer: TransitStopSyncer?
    
    @Published var transitLines: [TransitLine] = []
    
    // MARK: Initialization
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lineSyncer = TransitLineSyncer(modelContext: modelContext)
        self.stationSyncer = TransitStationSyncer(modelContext: modelContext)
        self.stopSyncer = TransitStopSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<TransitLine>(sortBy: [SortDescriptor(\.name)])
            self.transitLines = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let lineSyncer = lineSyncer, let stationSyncer = stationSyncer, let stopSyncer = stopSyncer else { return }
        
        do {
            _ = try await lineSyncer.pullChanges()
            _ = try await stationSyncer.pullChanges()
            _ = try await stopSyncer.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to pull transit data: \(error)")
        }
    }
    
    func fetchArchivedFromServer() async {
        await executeFetchArchived(refreshAction: refreshFromServer)
    }
    
    func purgeArchivedFromCache() {
        executePurgeArchived(type: TransitLine.self, context: modelContext, fetchAction: fetchFromCache)
    }
    
    func uploadLocalChanges() async {
        print("Upload not allowed for Transit Lines.")
    }
}
