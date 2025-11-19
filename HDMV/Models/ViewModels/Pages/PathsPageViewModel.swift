//
//  ActivitiesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData

@MainActor
class PathsPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private var pathSyncer: PathSyncer?
    
    @Published var isLoading = false
    @Published var paths: [Path] = []
    
    private let tripsService = TripsService()
    private var gpxParser = GPXParserService()
    private let storageService = StorageService()
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.pathSyncer = PathSyncer(modelContext: modelContext)
    }
    
    // MARK: - Data Fetching and Management
    
    func fetchFromCache() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Path>()
        do {
            self.paths = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch interactions: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = pathSyncer else {
            print("⚠️ [PathsPageViewModel] countriesSyncer is nil")
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
        guard let syncer = pathSyncer else {
            print("⚠️ [PathsPageViewModel] countriesSyncer is nil")
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
    
    func createLocalPath() {
        guard let context = modelContext else { return }
        let newPath =
            Path(
                syncStatus: .local
            )
        context.insert(newPath)
        do {
            try context.save()
        } catch {
            print("Failed to create path: \(error)")
        }
    }
    
    

}
