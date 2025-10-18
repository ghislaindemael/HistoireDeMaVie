//
//  ActivitiesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData

@MainActor
class ActivitiesPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private var activitySyncer: ActivitySyncer?
    
    @Published var isLoading = false
    @Published var activities: [Activity] = []
    
    // MARK: - Computed Properties for Views
    var hasLocalChanges: Bool {
        return activities.contains(where: { $0.hasUnsyncedChanges })
    }
    
    // MARK: Initialization
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.activitySyncer = ActivitySyncer(modelContext: modelContext)
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
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
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
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    
    // MARK: User Actions
    
    func createActivity() {
        guard let context = modelContext else { return }
        let newActivity = Activity(syncStatus: .local)
        
        context.insert(newActivity)
        activities.append(newActivity)
        do {
            try context.save()
        } catch {
            print("Failed to create Activity: \(error)")
        }
    }
    
}
