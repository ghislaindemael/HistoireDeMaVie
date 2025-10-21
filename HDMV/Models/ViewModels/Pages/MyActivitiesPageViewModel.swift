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
    
    enum FilterMode: Hashable {
        case byDate
        case byActivity
    }
    
    private var modelContext: ModelContext?
    private var masterSyncer: MasterSyncer?
    private var settings: SettingsStore = SettingsStore.shared

    @Published var isLoading: Bool = false
    
    @Published var filterMode: FilterMode = .byDate
    // State for the 'byDate' mode
    @Published var filterDate: Date = .now
    // State for the 'byActivity' mode
    @Published var filterActivity: Activity?
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @Published var filterEndDate: Date = .now
    
    
    @Published var instances: [ActivityInstance] = []
    @Published var trips: [Trip] = []
    @Published var interactions: [Interaction] = []
    
    @Published var activityTree: [Activity] = []
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.masterSyncer = MasterSyncer(modelContext: modelContext)
    }
    
    func fetchDailyData() {
        fetchInstances()
        fetchTrips()
        fetchInteractions()
    }
 
    /// A single, powerful function to fetch instances based on the current filter mode.
    func fetchInstances() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<ActivityInstance>
        
        switch filterMode {
            case .byDate:
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterDate)
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
                
                guard let activity = filterActivity else {
                    self.instances = []
                    return
                }
                
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterStartDate)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: filterEndDate)) ?? filterEndDate
                let future = Date.distantFuture
                
                let targetActivityID = activity.id
                let activityPredicate = #Predicate<ActivityInstance> { instance in
                    instance.activity?.id == targetActivityID
                }
                
                let timePredicate = #Predicate<ActivityInstance> { instance in
                    instance.time_start < endOfDay &&
                    (instance.time_end ?? future) > startOfDay
                }
                
                let combinedPredicate = #Predicate<ActivityInstance> { instance in
                    activityPredicate.evaluate(instance) &&
                    timePredicate.evaluate(instance)
                }

                descriptor = FetchDescriptor<ActivityInstance>(
                    predicate: combinedPredicate,
                    sortBy: [SortDescriptor(\.time_start, order: .reverse)]
                )
        }
        
        do {
            self.instances = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch activity instances: \(error)")
        }
    }
    
    func fetchTrips() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<Trip>
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: filterDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let future = Date.distantFuture
        
        let predicate = #Predicate<Trip> {
            $0.time_start < endOfDay &&
            ($0.time_end ?? future) > startOfDay
        }
        descriptor = FetchDescriptor<Trip>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.time_start, order: .reverse)]
        )
        
        do {
            self.trips = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch trips: \(error)")
        }
    }
    
    func fetchInteractions() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<Interaction>
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: filterDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let future = Date.distantFuture
        
        
        let predicate = #Predicate<Interaction> {
            $0.time_start < endOfDay &&
            ($0.time_end ?? future) > startOfDay
        }
        descriptor = FetchDescriptor<Interaction>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.time_start, order: .reverse)]
        )
        
        do {
            self.interactions = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch interactions: \(error)")
        }
    }
    
    
    // MARK: - Core Synchronization Logic
        
    func syncWithServer() async {
        isLoading = true
        defer { isLoading = false }
        await masterSyncer?.sync(
            filterMode: self.filterMode,
            date: self.filterDate,
            activityRid: self.filterActivity?.rid,
            startDate: self.filterStartDate,
            endDate: self.filterEndDate
        )
        fetchDailyData()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await masterSyncer?.pushChanges()
        } catch {
            print("MasterSyncer changes upload failed: \(error)")
        }
        fetchDailyData()
    }
    
    
    
    // MARK: - Local Cache Creation
    
    func createTrip(parent: ActivityInstance) {
        guard let context = modelContext else { return }
        
        var date = Date.now
        if settings.planningMode {
            date = parent.time_start
        }
        let newTrip = Trip(
            time_start: date,
            parentInstance: parent
        )
        context.insert(newTrip)
        do {
            try context.save()
            self.trips.insert(newTrip, at: 0)
        } catch {
            print("Failed to create new trip: \(error)")
        }
    }
    
    func endTrip(trip: Trip){
        guard let context = modelContext else { return }
        do {
            trip.time_end = .now
            trip.markAsModified()
            try context.save()
        } catch {
            print("Failed to end trip: \(error)")
        }
    }
    
    func claim(trip: Trip, for instance: ActivityInstance) {
        guard let context = modelContext else { return }
        
        do {
            trip.parentInstance = instance
            trip.markAsModified()
            try context.save()
        } catch {
            print("Failed to claim trip: \(error)")
        }
    }
        
    func createActivityInstance(date: Date? = nil) {
        guard let context = modelContext else { return }
        
        let startTime: Date
        if let specificDate = date {
            startTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: specificDate) ?? specificDate
        } else {
            startTime = .now
        }
        
        let newInstance = ActivityInstance(
            time_start: startTime,
            syncStatus: .local
        )
        
        context.insert(newInstance)
        do {
            try context.save()
            self.instances.append(newInstance)
            self.instances.sort { $0.time_start > $1.time_start }
        } catch {
            print("Failed to save new instance: \(error)")
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
    
    func createInteraction(parent: ActivityInstance) {
        guard let context = modelContext else { return }
        let newInteraction = Interaction(
            time_start: .now,
            parentInstance: parent
        )
        context.insert(newInteraction)
        do {
            try context.save()
            self.interactions.append(newInteraction)
        } catch {
            print("Failed to create interaction: \(error)")
        }
    }
    
    func endInteraction(interaction: Interaction){
        guard let context = modelContext else { return }
        do {
            interaction.time_end = .now
            interaction.markAsModified()
            try context.save()
        } catch {
            print("Failed to end interaction: \(error)")
        }
    }
    

    func reparent(draggedItem: DraggableLogItem, to newParent: ActivityInstance) {
        guard let context = modelContext else {
            print("❌ Reparent failed: modelContext is nil.")
            return
        }
        
        switch draggedItem {
            case .activity(let childID):
                guard let childToMove = context.model(for: childID) as? ActivityInstance else { return }
                
                guard childToMove.id != newParent.id else {
                    print("⚠️ SKIPPED: Cannot drop an activity onto itself.")
                    return
                }
                
                guard !isCircularDependency(moving: childToMove, to: newParent) else {
                    print("❌ FAILED: Circular dependency detected! Cannot move an item into one of its own descendants.")
                    return
                }
                
                print("✅ Re-parenting Activity '\(childToMove.id)' onto '\(newParent.id)'.")
                childToMove.parent = newParent
                childToMove.markAsModified()
                
            case .trip(let childID):
                guard let childToMove = context.model(for: childID) as? Trip else { return }
                
                print("✅ Re-parenting Trip '\(childToMove.id)' onto '\(newParent.id)'.")
                childToMove.parentInstance = newParent
                childToMove.markAsModified()
                
            case .interaction(let childID):
                guard let childToMove = context.model(for: childID) as? Interaction else { return }
                
                print("✅ Re-parenting Interaction '\(childToMove.id)' onto '\(newParent.id)'.")
                childToMove.parentInstance = newParent
                childToMove.markAsModified()
        }
        
        do {
            try context.save()
            fetchDailyData()
            print("✅ Save successful.")
        } catch {
            print("❌ FAILED to save re-parenting change: \(error)")
        }
    }
    
    private func isCircularDependency(moving child: ActivityInstance, to potentialParent: ActivityInstance) -> Bool {
        var parentIterator: ActivityInstance? = potentialParent
        
        while let currentParent = parentIterator {
            if currentParent == child {
                return true
            }
            parentIterator = currentParent.parent
        }
        return false
    }
    
}
