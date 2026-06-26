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
    

    
    private var modelContext: ModelContext?
    private var masterSyncer: MasterSyncer?
    private var settings: SettingsStore = SettingsStore.shared

    @Published var isLoading: Bool = false
    
    @Published var filterMode: TimelineFilterMode = .daily {
        didSet { scrollResetID = UUID() }
    }
    // State for the 'byDate' mode
    @Published var filterDate: Date = .now {
        didSet { scrollResetID = UUID() }
    }
    // State for the 'byActivity' mode
    @Published var filterActivity: Activity? {
        didSet { scrollResetID = UUID(); fetchDailyData() }
    }
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now {
        didSet { scrollResetID = UUID(); fetchDailyData() }
    }
    @Published var filterEndDate: Date = .now {
        didSet { scrollResetID = UUID(); fetchDailyData() }
    }
    
    @Published var scrollResetID = UUID()
    
    
    @Published var instances: [ActivityInstance] = []
    @Published var trips: [Trip] = []
    @Published var interactions: [Interaction] = []
    @Published var lifeEvents: [LifeEvent] = []
    @Published var quotes: [Quote] = []
    
    var timelineItems: [any LogModel] {
        let combined: [any LogModel] = (instances as [any LogModel]) + (lifeEvents as [any LogModel]) + (quotes as [any LogModel])
        return combined.sorted { $0.timeStart > $1.timeStart }
    }
    
    @Published var activityTree: [Activity] = []
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.masterSyncer = MasterSyncer(modelContext: modelContext)
    }
    
    func fetchDailyData() {
        fetchInstances()
        fetchTrips()
        fetchInteractions()
        fetchLifeEvents()
        fetchQuotes()
    }
 
    /// A single, powerful function to fetch instances based on the current filter mode.
    func fetchInstances() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<ActivityInstance>
        
        switch filterMode {
            case .daily:
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
                let future = Date.distantFuture
                
                let predicate = #Predicate<ActivityInstance> {
                    $0.parentInstance == nil &&
                    $0.parentTrip == nil &&
                    $0.timeStart < endOfDay &&
                    ($0.timeEnd ?? future) > startOfDay
                }
                descriptor = FetchDescriptor<ActivityInstance>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
                )
                
            case .advanced:
                
                guard let activity = filterActivity else {
                    self.instances = []
                    return
                }
                
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterStartDate)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: filterEndDate)) ?? filterEndDate
                let future = Date.distantFuture
                
                let targetActivityID = activity.rid
                let activityPredicate = #Predicate<ActivityInstance> { instance in
                    instance.activityRid == targetActivityID
                }
                
                let timePredicate = #Predicate<ActivityInstance> { instance in
                    instance.timeStart < endOfDay &&
                    (instance.timeEnd ?? future) > startOfDay
                }
                
                let combinedPredicate = #Predicate<ActivityInstance> { instance in
                    activityPredicate.evaluate(instance) &&
                    timePredicate.evaluate(instance)
                }

                descriptor = FetchDescriptor<ActivityInstance>(
                    predicate: combinedPredicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
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
            $0.timeStart < endOfDay &&
            ($0.timeEnd ?? future) > startOfDay
        }
        descriptor = FetchDescriptor<Trip>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
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
            $0.timeStart < endOfDay &&
            ($0.timeEnd ?? future) > startOfDay
        }
        descriptor = FetchDescriptor<Interaction>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
        )
        
        do {
            self.interactions = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch interactions: \(error)")
        }
    }
    
    func fetchLifeEvents() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<LifeEvent>
        
        switch filterMode {
            case .daily:
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
                
                let predicate = #Predicate<LifeEvent> {
                    $0.parentInstance == nil &&
                    $0.parentTrip == nil &&
                    $0.timeStart < endOfDay &&
                    ($0.timeEnd ?? $0.timeStart) >= startOfDay
                }
                descriptor = FetchDescriptor<LifeEvent>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
                )
                
            case .advanced:
                self.lifeEvents = []
                return
        }
        
        do {
            let fetchedEvents = try context.fetch(descriptor)
            self.lifeEvents = fetchedEvents
        } catch {
            print("Failed to fetch LifeEvents: \(error)")
        }
    }
    
    func fetchQuotes() {
        guard let context = modelContext else { return }
        
        let descriptor: FetchDescriptor<Quote>
        
        switch filterMode {
            case .daily:
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
                
                let predicate = #Predicate<Quote> {
                    $0.timeStart >= startOfDay &&
                    $0.timeStart < endOfDay
                }
                descriptor = FetchDescriptor<Quote>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
                )
            case .advanced:
                // No quotes for activity mode (they are fetched as children)
                descriptor = FetchDescriptor<Quote>(
                    predicate: #Predicate<Quote> { _ in false }
                )
        }
        
        do {
            let fetchedQuotes = try context.fetch(descriptor)
            // Filter in-memory to avoid `#Predicate` compiler timeout
            self.quotes = fetchedQuotes.filter { 
                $0.parentInstance == nil && 
                $0.parentTrip == nil && 
                $0.parentInteraction == nil 
            }
        } catch {
            print("Failed to fetch Quotes: \(error)")
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
    
    func createActivityInstance(date: Date? = nil) {
        guard let context = modelContext else { return }
        let smartDate = (date ?? filterDate).smartCreationTime
        updateFilterDateIfNeeded(for: smartDate)
        ActivityInstance.create(in: context, date: smartDate)
        fetchDailyData()
    }
    
    func createParentAndChildActivity(date: Date? = nil) {
        guard let context = modelContext else { return }
        let smartDate = (date ?? filterDate).smartCreationTime
        updateFilterDateIfNeeded(for: smartDate)
        
        let parentInstance = ActivityInstance.create(in: context, date: smartDate)
        
        let childDate = smartDate.addingTimeInterval(1)
        let childInstance = ActivityInstance.create(in: context, date: childDate)
        childInstance.parentInstance = parentInstance
        
        fetchDailyData()
    }
    
    func createTransaction() {
        guard let context = modelContext else { return }
        let smartDate = filterDate.smartCreationTime
        updateFilterDateIfNeeded(for: smartDate)
        Transaction.create(in: context, date: smartDate)
        fetchDailyData()
    }
    
    func createLifeEvent() {
        guard let context = modelContext else { return }
        let smartDate = filterDate.smartCreationTime
        updateFilterDateIfNeeded(for: smartDate)
        LifeEvent.create(in: context, date: smartDate)
        fetchDailyData()
    }
    
    func createQuote() {
        guard let context = modelContext else { return }
        let smartDate = filterDate.smartCreationTime
        updateFilterDateIfNeeded(for: smartDate)
        Quote.create(in: context, date: smartDate)
        fetchDailyData()
    }
    
    func createTrip(parent: ActivityInstance) {
        guard let context = modelContext else { return }
        Trip.create(in: context, parent: parent, filterDate: filterDate)
        fetchDailyData()
    }
    
    func createInteraction(parent: ActivityInstance) {
        guard let context = modelContext else { return }
        Interaction.create(in: context, parent: parent)
        fetchDailyData()
    }
    
    func endTrip(trip: Trip){
        guard let context = modelContext else { return }
        do {
            let now = Date.now
            if now > trip.timeStart {
                trip.timeEnd = now
            } else {
                trip.timeEnd = trip.timeStart
            }
            trip.markAsModified()
            try context.save()
        } catch {
            print("Failed to end trip: \(error)")
        }
    }
            
    
    func endActivityInstance(instance: ActivityInstance){
        guard let context = modelContext else { return }
        do {
            let now = Date.now
            if now > instance.timeStart {
                instance.timeEnd = now
            } else {
                instance.timeEnd = instance.timeStart
            }
            instance.markAsModified()
            try context.save()
        } catch {
            print("Failed to end activity.")
        }
    }

    
    func endInteraction(interaction: Interaction){
        guard let context = modelContext else { return }
        do {
            interaction.timeEnd = .now
            interaction.markAsModified()
            try context.save()
        } catch {
            print("Failed to end interaction: \(error)")
        }
    }
    
    
    
    // MARK: - Helper Logic
    
    private func getSmartCreationDate() -> Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(filterDate) {
            return Date.now
        } else {
            // Return noon on the selected filter date
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: filterDate) ?? filterDate
        }
    }
    
    private func updateFilterDateIfNeeded(for smartDate: Date) {
        let calendar = Calendar.current
        if calendar.isDateInToday(smartDate) && !calendar.isDateInToday(filterDate) {
            filterDate = .now
        }
    }
    
    private func saveContext() {
        do {
            try modelContext?.save()
            fetchDailyData()
        } catch {
            print("❌ Failed to create item: \(error)")
        }
    }
    

    func reparent(draggedItem: DraggableLogItem, to newParent: any ParentModel) {
        guard let context = modelContext else {
            print("❌ Reparent failed: modelContext is nil.")
            return
        }
        
        func move<T: LinkedParent & LogModel>(_ item: T) {
            var item = item
            guard item.id != newParent.id else {
                print("⚠️ SKIPPED: Cannot drop an item onto itself.")
                return
            }
            
            guard !isCircularDependency(moving: item, to: newParent) else {
                print("❌ FAILED: Circular dependency detected!")
                return
            }
            
            print("✅ Re-parenting '\(item.id)' onto '\(newParent.id)'.")
            item.setParent(newParent)
            item.markAsModified()
        }
        
        switch draggedItem {
            case .activity(let childID):
                if let child = context.model(for: childID) as? ActivityInstance {
                    move(child)
                }
            case .trip(let childID):
                if let child = context.model(for: childID) as? Trip {
                    move(child)
                }
            case .interaction(let childID):
                if let child = context.model(for: childID) as? Interaction {
                    move(child)
                }
            case .lifeEvent(let childID):
                if let child = context.model(for: childID) as? LifeEvent {
                    move(child)
                }
            case .quote(let childID):
                if let child = context.model(for: childID) as? Quote {
                    move(child)
                }
        }
        
        do {
            try context.save()
            fetchDailyData()
            print("✅ Save successful.")
        } catch {
            print("❌ FAILED to save re-parenting change: \(error)")
        }
    }
    
    private func isCircularDependency(moving child: any LogModel, to potentialParent: any ParentModel) -> Bool {
        var parentIterator: (any LinkedParent)? = potentialParent as? LinkedParent
        
        while let currentParent = parentIterator {
            if let logParent = currentParent as? any ParentModel, logParent.id == child.id {
                return true
            }
            parentIterator = currentParent.parentInstance ?? currentParent.parentTrip
        }
        return false
    }
    
}
