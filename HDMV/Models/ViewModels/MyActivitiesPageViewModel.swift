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
    
    enum FilterMode {
        case byDate
        case byActivity
    }
    
    private var modelContext: ModelContext?
    private var activityInstanceSyncer: ActivityInstanceSyncer?
    private var tripLegSyncer: TripLegSyncer?
    //private var interactionSyncer: PersonInteractionSyncer?
    private let instanceService = ActivityInstanceService()
    private let tripLegsService = TripsService()
    @Published var isLoading: Bool = false
    
    @Published var filterMode: FilterMode = .byDate
    // State for the 'byDate' mode
    @Published var selectedDate: Date = .now
    // State for the 'byActivity' mode
    @Published var filterActivityId: Int?
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @Published var filterEndDate: Date = .now
    
    
    @Published var instances: [ActivityInstance] = []
    @Published var tripLegs: [TripLeg] = []
    @Published var interactions: [PersonInteraction] = []
    
    @Published var activityTree: [Activity] = []
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.activityInstanceSyncer = ActivityInstanceSyncer(modelContext: modelContext)
        self.tripLegSyncer = TripLegSyncer(modelContext: modelContext)
        // self.interactionSyncer = PersonInteractionSyncer(modelContext: modelContext)
        fetchActivities()
    }
    
    private func fetchActivities() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Activity>(sortBy: [SortDescriptor(\.name)])
            self.activityTree = Activity.buildTree(from: try context.fetch(descriptor))
        } catch {
            print("Failed to fetch catalogue data: \(error)")
        }
    }
    
    private func fetchData() {
        fetchActivities()
        fetchDailyData()
    }
    
    func fetchDailyData() {
        fetchInstances()
        fetchTripLegs()
        fetchInteractions()
    }
 
    /// A single, powerful function to fetch instances based on the current filter mode.
    func fetchInstances() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<ActivityInstance>
        
        switch filterMode {
            case .byDate:
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: selectedDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
                let future = Date.distantFuture
                
                let predicate = #Predicate<ActivityInstance> {
                    $0.time_start < endOfDay &&
                    ($0.time_end ?? future) > startOfDay
                }
                descriptor = FetchDescriptor<ActivityInstance>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.time_start, order: .reverse)]
                )
                
            case .byActivity:
                
                guard let activityId = filterActivityId else {
                    self.instances = []
                    return
                }
                
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterStartDate)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: filterEndDate)) ?? filterEndDate
                let future = Date.distantFuture
                
                let predicate = #Predicate<ActivityInstance> { instance in
                    instance.activity_id == activityId &&
                    instance.time_start < endOfDay &&
                    (instance.time_end ?? future) > startOfDay
                }
                descriptor = FetchDescriptor<ActivityInstance>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.time_start, order: .reverse)]
                )
        }
        
        do {
            self.instances = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch activity instances: \(error)")
        }
    }
    
    func fetchTripLegs() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<TripLeg>
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let future = Date.distantFuture
        
        let predicate = #Predicate<TripLeg> {
            $0.time_start < endOfDay &&
            ($0.time_end ?? future) > startOfDay
        }
        descriptor = FetchDescriptor<TripLeg>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.time_start, order: .reverse)]
        )
        
        do {
            self.tripLegs = try context.fetch(descriptor)
            print("Fetched \(self.tripLegs.count) trip legs")
        } catch {
            print("Failed to fetch trip legs: \(error)")
        }
    }
    
    func fetchInteractions() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<PersonInteraction>
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let future = Date.distantFuture
        
        
        let predicate = #Predicate<PersonInteraction> {
            $0.time_start < endOfDay &&
            ($0.time_end ?? future) > startOfDay
        }
        descriptor = FetchDescriptor<PersonInteraction>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.time_start, order: .reverse)]
        )
        
        do {
            self.interactions = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch interactions: \(error)")
        }
    }
    
    // MARK: Transmitted data
    
    /// Helper function to find an activity by its ID in the tree.
    func findActivity(by id: Int?) -> Activity? {
        guard let id = id else { return nil }
        return activityTree.flatMap { $0.flattened() }.first { $0.id == id }
    }
    
    func tripLegs(for instanceId: Int) -> [TripLeg] {
        return self.tripLegs.filter { $0.parent_id == instanceId }
    }
    
    func interactions(for id: Int) -> [PersonInteraction] {
        return interactions.filter { $0.parent_activity_id == id }
    }
    
    // MARK: - Core Synchronization Logic
    
    /// Performs a full two-way sync. Ideal for the 'refresh' button or for backfilling old dates.
    /// It pushes local changes first to prevent conflicts, then pulls all remote changes.
    func syncWithServer() async {
        guard let activityInstanceSyncer = activityInstanceSyncer,
              let tripLegSyncer = tripLegSyncer else { return }
        
        print("⏳ Starting full two-way sync...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await activityInstanceSyncer.sync()
            try await tripLegSyncer.sync()
            
            fetchData()
            print("✅ Full sync completed.")
        } catch {
            print("❌ A full sync error occurred: \(error)")
        }
    }
    
    /// Performs a push-only operation to upload local creations, updates, and deletions.
    /// Ideal for the 'sync local changes' button.
    func uploadLocalChanges() async {
        guard let activityInstanceSyncer = activityInstanceSyncer,
              let tripLegSyncer = tripLegSyncer else { return }
        
        print("⏳ Uploading local changes...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            
            let instanceIdMap = try await activityInstanceSyncer.pushChanges()
            
            try await activityInstanceSyncer.updateChildrenWithNewParentIDs(instanceIdMap)
            
            try await tripLegSyncer.updateChildrenWithNewParentIDs(instanceIdMap)
            _ = try await tripLegSyncer.pushChanges()
            
            // try await interactionSyncer.updateChildrenWithNewParentIDs(idMap)
            // try await interactionSyncer.pushChanges()
            
            fetchData()
            print("✅ Local changes uploaded successfully.")
            
        } catch {
            print("❌ An error occurred while uploading local changes: \(error)")
        }
    }
    
    
    
    // MARK: - Local Cache Creation
    
    func createTripLeg(parent_id: Int) {
        guard let context = modelContext else { return }
        let newLeg = TripLeg(
            id: Int.random(in: -999999 ... -1),
            parent_id: parent_id,
            time_start: .now
        )
        context.insert(newLeg)
        do {
            try context.save()
            self.tripLegs.insert(newLeg, at: 0)
        } catch {
            print("Failed to create new trip: \(error)")
        }
    }
    
    func endTripLeg(leg: TripLeg){
        guard let context = modelContext else { return }
        do {
            leg.time_end = .now
            leg.syncStatus = .local
            try context.save()
        } catch {
            print("Failed to end trip: \(error)")
        }
    }
    
    func claim(tripLeg: TripLeg, for instance: ActivityInstance) {
        guard let context = modelContext else { return }
        
        if let legToUpdate = self.tripLegs.first(where: { $0.id == tripLeg.id }) {
            legToUpdate.parent_id = instance.id
            legToUpdate.syncStatus = .local
            try? context.save()
        }
    }
        
    func createActivtiyInstance() {
        guard let context = modelContext else { return }
        let newInstance = ActivityInstance(id: Int.random(in: -999999 ... -1), time_start: .now, syncStatus: .local)
        context.insert(newInstance)
        do {
            try context.save()
            self.instances.insert(newInstance, at: 0)
        } catch {
            print("Failed to save new instance: \(error)")
        }
    }
    
    func createActivityInstanceForDate() {
        guard let context = modelContext else { return }
        let noonOnSelectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let newInstance = ActivityInstance(id: Int.random(in: -999999 ... -1), time_start: noonOnSelectedDate, syncStatus: .local)
        context.insert(newInstance)
        do {
            try context.save()
            self.instances.append(newInstance)
            self.instances.sort { $0.time_start > $1.time_start }
        } catch {
            print("Failed to save new instance at noon: \(error)")
        }
    }
    
    func endActivityInstance(instance: ActivityInstance){
        guard let context = modelContext else { return }
        do {
            instance.time_end = .now
            instance.syncStatus = .local
            try context.save()
        } catch {
            print("Failed to end activity.")
        }
    }
    
    func createInteraction(parent_id: Int) {
        guard let context = modelContext else { return }
        let newInteraction = PersonInteraction(
            id: Int.random(in: -999999 ... -1),
            time_start: .now,
            parent_activity_id: parent_id
        )
        context.insert(newInteraction)
        do {
            try context.save()
            self.interactions.append(newInteraction)
        } catch {
            print("Failed to create interaction: \(error)")
        }
    }
    
    func endInteraction(interaction: PersonInteraction){
        guard let context = modelContext else { return }
        do {
            interaction.time_end = .now
            interaction.syncStatus = .local
            try context.save()
        } catch {
            print("Failed to end interaction: \(error)")
        }
    }
    
    func claim(interaction: PersonInteraction, for instance: ActivityInstance) {
        guard let context = modelContext else { return }
        
        if let intToUpdate = self.interactions.first(where: { $0.id == interaction.id }) {
            intToUpdate.parent_activity_id = instance.id
            intToUpdate.syncStatus = .local
            try? context.save()
        }
    }
    
    func reparent(instanceId: Int, toNewParentInstanceId newParentInstanceId: Int) {
        print("--- [Debug] Attempting to reparent instance '\(instanceId)' onto '\(newParentInstanceId)' ---")
        
        guard let context = modelContext else {
            print("❌ [Debug] FAILED: modelContext is nil.")
            return
        }
        
        guard instanceId != newParentInstanceId else {
            print("⚠️ [Debug] SKIPPED: Attempted to drop an instance onto itself.")
            return
        }
        
        let childInstanceToMove = instances.first { $0.id == instanceId }
        let newParentInstance = instances.first { $0.id == newParentInstanceId }
        
        guard let childInstanceToMove = childInstanceToMove, let newParentInstance = newParentInstance else {
            print("❌ [Debug] FAILED: Could not find instances in local data.")
            return
        }
        
        var parentIterator = newParentInstance.parent
        while parentIterator != nil {
            if parentIterator?.id == childInstanceToMove.id {
                print("❌ [Debug] FAILED: Circular dependency detected!")
                return
            }
            parentIterator = parentIterator?.parent
        }
        
        print("✅ [Debug] Re-parenting instance '\(childInstanceToMove.id)' to '\(newParentInstance.id)'.")
        childInstanceToMove.parent = newParentInstance
        childInstanceToMove.syncStatus = .local
        
        do {
            try context.save()
            print("✅ [Debug] Save successful.")
            fetchDailyData()
        } catch {
            print("❌ [Debug] FAILED to save re-parenting change: \(error)")
        }
    }
    
}
