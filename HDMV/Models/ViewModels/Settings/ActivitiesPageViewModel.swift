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
    
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchFromCache()
        if activityTree.isEmpty {
            Task { await fetchFromServer() }
        }
    }
    
    // MARK: - Data Fetching and Management
    
    func fetchFromServer() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let activityDtos = try await activitiesService.fetchActivities()
            let activities = activityDtos.map { Activity(fromDto: $0) }
            self.activityTree = Activity.buildTree(from: activities)
            await cacheAllActivities(from: activities)
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
    
    // Renamed for clarity
    private func cacheAllActivities(from activities: [Activity]) async {
        guard let context = modelContext else { return }
        
        do {
            try context.delete(model: Activity.self)
            
            for activity in activities where activity.cache {
                context.insert(activity)
            }
            try context.save()
        } catch {
            print("Failed to cache activities: \(error)")
        }
    }
    
    func cacheCurrentActivities() async {
        await cacheAllActivities(from: self.allActivities)
    }
    
    // MARK: - CRUD Actions
    
    func createActivity(payload: NewActivityPayload) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await activitiesService.createActivity(payload: payload)
            await fetchFromServer()
        } catch {
            print("❌ Create error: \(error)")
        }
    }
        
    func archiveActivity(_ activity: Activity) async {
        do {
            try await activitiesService.archiveActivity(for: activity)
            await fetchFromServer()
        } catch {
            print("❌ Archive error: \(error)")
        }
    }
    
    func unarchiveActivity(_ activity: Activity) async {
        do {
            try await activitiesService.unarchiveActivity(for: activity)
            await fetchFromServer()
        } catch {
            print("❌ Unarchive error: \(error)")
        }
    }
    
    // MARK: - Granular Cache Updates
    
    /// **NEW**: A private helper to update a specific branch in the SwiftData cache.
    /// It deletes all existing records for the branch and re-inserts only those marked for caching.
    private func updateCache(forBranch startingActivity: Activity) async {
        guard let context = modelContext else { return }
        
        let branchActivities = startingActivity.flattened()
        let branchIDs = branchActivities.map { $0.id }
        
        let predicate = #Predicate<Activity> { activity in
            branchIDs.contains(activity.id)
        }
        
        do {
            try context.delete(model: Activity.self, where: predicate)
            
            for activity in branchActivities where activity.cache {
                context.insert(activity)
            }
            
            try context.save()
            print("✅ Successfully updated cache for branch: \(startingActivity.name)")
        } catch {
            print("❌ Failed to perform branch update on cache: \(error)")
        }
    }
    

    func toggleCache(for activity: Activity) async {
        let newCacheState = !activity.cache
        
        if !newCacheState {
            setCacheState(for: activity, to: false)
        } else {
            activity.cache = newCacheState
        }
        
        do {
            try await activitiesService.updateCacheStatus(for: activity)
            
            await cacheAllActivities(from: allActivities)
        } catch {
            print("❌ Failed to update cache status in DB. Reverting change. Error: \(error)")
            setCacheState(for: activity, to: !newCacheState)
        }
    }
    
    private func setCacheState(for activity: Activity, to state: Bool) {
        // If we are turning caching OFF, we must turn it off for all children.
        // If we are turning it ON, we only turn it on for the selected activity.
        if !state {
            activity.cache = false
            for child in activity.children {
                setCacheState(for: child, to: false)
            }
        } else {
            activity.cache = true
        }
    }
}
