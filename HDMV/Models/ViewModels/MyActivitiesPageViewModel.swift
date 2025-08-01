//
//  MyActivitiesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import Foundation
import SwiftData

@MainActor
class MyActivitiesPageViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published private(set) var instances: [ActivityInstance] = []
    @Published private(set) var activityTree: [Activity] = []
    
    private var modelContext: ModelContext?
    private let service = ActivityInstanceService()
    
    var hasLocalChanges: Bool {
        instances.contains { $0.syncStatus != .synced }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchActivities()
    }
    
    /// ADDED: Fetches all activities from the cache and builds the tree structure.
    private func fetchActivities() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Activity>(sortBy: [SortDescriptor(\.name)])
            let allActivities = try context.fetch(descriptor)
            self.activityTree = Activity.buildTree(from: allActivities)
        } catch {
            print("Failed to fetch activities: \(error)")
        }
    }
    
    // MARK: - Core Synchronization Logic
    
    func syncWithServer(for date: Date) async {
        guard let context = modelContext else { return }
        isLoading = true
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = #Predicate<ActivityInstance> { $0.time_start >= startOfDay && $0.time_start < endOfDay }
        
        do {
            let onlineInstances = try await service.fetchActivityInstances(for: date)
            let onlineDict = Dictionary(uniqueKeysWithValues: onlineInstances.map { ($0.id, $0) })
            
            let descriptor = FetchDescriptor<ActivityInstance>(predicate: predicate)
            let localInstances = try context.fetch(descriptor)
            let localDict = Dictionary(uniqueKeysWithValues: localInstances.map { ($0.id, $0) })
            
            for dto in onlineInstances {
                if let localInstance = localDict[dto.id] {
                    if localInstance.syncStatus == .synced {
                        localInstance.time_start = dto.time_start
                        localInstance.time_end = dto.time_end
                        localInstance.activity_id = dto.activity_id
                        localInstance.details = dto.details
                    }
                } else {
                    context.insert(ActivityInstance(from: dto))
                }
            }
            
            for localInstance in localInstances {
                if onlineDict[localInstance.id] == nil && localInstance.syncStatus == .synced {
                    context.delete(localInstance)
                }
            }
            
            try context.save()
            
            let refreshedDescriptor = FetchDescriptor<ActivityInstance>(predicate: predicate, sortBy: [SortDescriptor(\.time_start, order: .reverse)])
            self.instances = try context.fetch(refreshedDescriptor)
            
        } catch {
            print("Error during sync: \(error)")
        }
        
        isLoading = false
    }
    
    func syncChanges() async {
        guard let context = modelContext else { return }
        
        let instancesToSync = self.instances.filter { $0.syncStatus != .synced }
        
        guard !instancesToSync.isEmpty else { return }
        
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            for instance in instancesToSync {
                group.addTask {
                    let payload = ActivityInstancePayload(
                        time_start: instance.time_start,
                        time_end: instance.time_end,
                        activity_id: instance.activity_id,
                        details: instance.details
                    )
                    do {
                        if instance.id < 0 {
                            let newDTO = try await self.service.createActivityInstance(payload)
                            instance.id = newDTO.id
                        } else {
                            _ = try await self.service.updateActivityInstance(id: instance.id, payload: payload)
                        }
                        instance.syncStatus = .synced
                    } catch {
                        print("Failed to sync instance \(instance.id): \(error). Marking as failed.")
                        instance.syncStatus = .failed
                    }
                }
            }
        }
        
        try? context.save()
        isLoading = false
    }
    
    // MARK: - Local Cache Creation
    
    func createNewInstanceInCache() {
        guard let context = modelContext else { return }
        
        let newInstance = ActivityInstance(
            id: Int.random(in: -999999 ... -1),
            time_start: .now,
            syncStatus: .local
        )
        context.insert(newInstance)
        
        do {
            try context.save()
            self.instances.insert(newInstance, at: 0)
        } catch {
            print("Failed to save new instance: \(error)")
        }
    }
    
    func createNewInstanceAtNoonInCache(for date: Date) {
        guard let context = modelContext else { return }
        
        let noonOnSelectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        
        let newInstance = ActivityInstance(
            id: Int.random(in: -999999 ... -1),
            time_start: noonOnSelectedDate,
            syncStatus: .local
        )
        context.insert(newInstance)
        
        do {
            try context.save()
            self.instances.append(newInstance)
            self.instances.sort { $0.time_start > $1.time_start }
        } catch {
            print("Failed to save new instance at noon: \(error)")
        }
    }
}

// Helper to create a Model from a DTO
extension ActivityInstance {
    convenience init(from dto: ActivityInstanceDTO) {
        self.init(id: dto.id, time_start: dto.time_start, time_end: dto.time_end, activity_id: dto.activity_id, details: dto.details, syncStatus: .synced)
    }
}
