//
//  ActivitiesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData

@MainActor
class ActivitiesPageViewModel: BasePageViewModel {
    
    private var activitySyncer: ActivitySyncer?
    private var optionSyncer: DataActivityOptionSyncer?
    private var mappingSyncer: DataActivityOptionMappingSyncer?
    
    @Published var activities: [Activity] = []
    
    // MARK: - Computed Properties for Views
    var hasLocalChanges: Bool {
        return activities.contains(where: { $0.hasUnsyncedChanges })
    }
    
    // MARK: Initialization
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.activitySyncer = ActivitySyncer(modelContext: modelContext)
        self.optionSyncer = DataActivityOptionSyncer(modelContext: modelContext)
        self.mappingSyncer = DataActivityOptionMappingSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let predicate = #Predicate<Activity> { $0.parent == nil }
            
            let descriptor = FetchDescriptor<Activity>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.name)]
            )
            
            self.activities = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = activitySyncer else {
            print("⚠️ [ActivitiesPageViewModel] Syncer is nil")
            return
        }
        do {
            try await syncer.pullChanges()
            try await optionSyncer?.pullChanges()
            try await mappingSyncer?.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func fetchArchivedFromServer() async {
        await executeFetchArchived(refreshAction: refreshFromServer)
    }
    
    func purgeArchivedFromCache() {
        executePurgeArchived(type: Activity.self, context: modelContext, fetchAction: fetchFromCache)
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = activitySyncer else {
            print("⚠️ [ActivitiesPageViewModel] countriesSyncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            _ = try await optionSyncer?.pushChanges()
            _ = try await mappingSyncer?.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    
    // MARK: User Actions
    
    func createActivity() {
        guard let context = modelContext else { return }
        let newActivity = Activity(syncStatus: .unsynced)
        
        context.insert(newActivity)
        activities.append(newActivity)
        do {
            try context.save()
        } catch {
            print("Failed to create Activity: \(error)")
        }
    }
    
}
