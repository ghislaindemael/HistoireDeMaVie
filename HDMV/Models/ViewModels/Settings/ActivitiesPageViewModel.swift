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
    @Published var activityTree: [Activity] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private let activitiesService = ActivitiesService()
    
    // MARK: - Computed Properties for Views
    var allActivities: [Activity] {
        activityTree.flatMap { $0.flattened() }
    }
    
    /// Checks if there are any activities that need to be synced with the server.
    var hasLocalChanges: Bool {
        return allActivities.contains(where: { $0.syncStatus != .synced })
    }
    
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchFromCache()
    }
    
    // MARK: - Data Fetching and Management
    
    func syncWithServer() async {
        
        guard let context = modelContext else { return }
        isLoading = true
        defer { isLoading = false }

    
        do {
            let onlineActivities = try await activitiesService.fetchActivities()
            let onlineDict = Dictionary(uniqueKeysWithValues: onlineActivities.map { ($0.id, $0) })
            
            let descriptor = FetchDescriptor<Activity>()
            let localActivities = try context.fetch(descriptor)
            let localDict = Dictionary(uniqueKeysWithValues: localActivities.map { ($0.id, $0) })
            
            for dto in onlineActivities {
                if let localActivity = localDict[dto.id] {
                    if localActivity.syncStatus == .synced {
                        localActivity.update(fromDto: dto)
                    }
                } else {
                    context.insert(Activity(fromDto: dto))
                }
            }
            
            for localActivity in localActivities {
                if onlineDict[localActivity.id] == nil && localActivity.syncStatus == .synced {
                    context.delete(localActivity)
                }
            }
            
            try context.save()
            
            let refreshedDescriptor = FetchDescriptor<Activity>(sortBy: [SortDescriptor(\.name)])
            let activities = try context.fetch(refreshedDescriptor)
            self.activityTree = Activity.buildTree(from: activities)
        } catch {
            print("Failed to fetch activities from server: \(error)")
        }
        
    }
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Activity>()
            let cachedActivities = try context.fetch(descriptor)
            self.activityTree = Activity.buildTree(from: cachedActivities)
        } catch {
            print("Failed to fetch activities from cache: \(error)")
        }
    }
    

    
    // MARK: Synchronization
    
    private func syncActivity(activity: Activity, in context: ModelContext) async {
        let payload = activity.toPayload()
        do {
            if activity.id < 0 {
                let temporaryId = activity.id
                let newDTO = try await self.activitiesService.createActivity(payload: payload)
                if let activityToUpdate = try context.fetch(FetchDescriptor<Activity>()).first(where: { $0.id == temporaryId }) {
                    activityToUpdate.id = newDTO.id
                    activityToUpdate.syncStatus = SyncStatus.synced
                }
            } else {
                _ = try await self.activitiesService.updateActivity(id: activity.id, payload: payload)
            }
            activity.syncStatus = .synced
        } catch {
            activity.syncStatus = .failed
            print("Failed to sync activity \(activity.name): \(error).")
        }
    }
    
    /// Uploads all activities marked as `.local` or `.failed` to the server.
    func syncLocalChanges() async {
        guard let context = modelContext else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allActivitiesInDB = try context.fetch(FetchDescriptor<Activity>())
            
            let activitiesToSync = allActivitiesInDB.filter {
                $0.syncStatus == .local || $0.syncStatus == .failed
            }
            
            guard !activitiesToSync.isEmpty else {
                print("✅ No local activity changes to sync.")
                return
            }
            
            print("⏳ Syncing \(activitiesToSync.count) activities...")
            
            await withTaskGroup(of: Void.self) { group in
                for activity in activitiesToSync {
                    group.addTask {
                        await self.syncActivity(activity: activity, in: context)
                    }
                }
            }
            
            try context.save()
            print("✅ Sync complete. Refreshing from server...")
            await syncWithServer()
            
        } catch {
            print("❌ Failed to fetch activities for syncing: \(error)")
        }
    }
    
    // MARK: Computed data
    
    func generateTempID() -> Int {
        let minID =
            activityTree.flatMap { $0.flattened() }
                .map(\.id).filter { $0 < 0 }.min() ?? 0
        return minID - 1
    }
    
    // MARK: User Actions
    
    func createLocalActivity() {
        guard let context = modelContext else { return }
        let newActivity =
        Activity(
            id: generateTempID(),
            name: "",
            slug: "",
            icon: "",
            permissions: [],
            syncStatus: .local
        )
        
        context.insert(newActivity)
        do {
            try context.save()
            self.activityTree.insert(newActivity, at: 0)
        } catch {
            print("Failed to create interaction: \(error)")
        }
    }
}
