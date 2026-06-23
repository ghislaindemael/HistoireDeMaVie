//
//  PeopleInteractionsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class MyInteractionsPageViewModel: ObservableObject {
    

    
    private var modelContext: ModelContext?
    private var masterSyncer: MasterSyncer?
    private var settings: SettingsStore = SettingsStore.shared
    
    @Published var isLoading: Bool = false
    
    @Published var filterMode: TimelineFilterMode = .daily {
        didSet { scrollResetID = UUID() }
    }
    @Published var filterDate: Date = .now {
        didSet { scrollResetID = UUID() }
    }
    
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now {
        didSet { scrollResetID = UUID(); fetchInteractions() }
    }
    @Published var filterEndDate: Date = .now {
        didSet { scrollResetID = UUID(); fetchInteractions() }
    }
    @Published var filterPerson: Person? {
        didSet { scrollResetID = UUID(); fetchInteractions() }
    }
    
    @Published var scrollResetID = UUID()
    
    @Published var interactions: [Interaction] = []
        
    var hasLocalChanges: Bool {
        interactions.contains { $0.syncStatus != .synced }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.masterSyncer = MasterSyncer(modelContext: modelContext)
    }
    
    // MARK: - Data Fetching
    
    func fetchInteractions() {
        guard let context = modelContext else { return }
        
        do {
            if filterMode == .daily {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
                let future = Date.distantFuture
                
                let predicate = #Predicate<Interaction> {
                    $0.timeStart < endOfDay &&
                    ($0.timeEnd ?? future) > startOfDay
                }
                let descriptor = FetchDescriptor<Interaction>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
                )
                
                self.interactions = try context.fetch(descriptor)
            } else {
                let startOfDay = Calendar.current.startOfDay(for: filterStartDate)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: filterEndDate)) ?? .now
                let future = Date.distantFuture
                
                // SwiftData predicate doesn't handle collection 'contains' with relationships well in all cases,
                // so we fetch by date and then filter by person in memory if needed.
                let predicate = #Predicate<Interaction> {
                    $0.timeStart < endOfDay &&
                    ($0.timeEnd ?? future) > startOfDay
                }
                let descriptor = FetchDescriptor<Interaction>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
                )
                
                var fetched = try context.fetch(descriptor)
                
                if let person = filterPerson, let personRid = person.rid {
                    fetched = fetched.filter { interaction in
                        interaction.personRids.contains(personRid)
                    }
                }
                
                self.interactions = fetched
            }
        } catch {
            print("Error during interaction fetch: \(error)")
            self.interactions = []
        }
    }

    
    // MARK: - Core Synchronization Logic
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        await masterSyncer?.sync(
            filterMode: self.filterMode,
            date: self.filterDate,
            personRid: self.filterPerson?.rid,
            startDate: self.filterStartDate,
            endDate: self.filterEndDate
        )
        fetchInteractions()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await masterSyncer?.pushChanges()
        } catch {
            print("MasterSyncer changes upload failed: \(error)")
        }
        fetchInteractions()
    }
    
    // MARK: User Actions
        
    func createInteraction(date: Date? = nil) {
        guard let context = modelContext else { return }
        let date = filterDate.smartCreationTime
        let newInteraction = Interaction(
            timeStart: date
        )
        context.insert(newInteraction)
        do {
            try context.save()
            self.interactions.append(newInteraction)
            self.interactions.sort { $0.timeStart > $1.timeStart }
        } catch {
            print("Failed to create interaction: \(error)")
        }
    }
    
    func deleteInteraction(_ interaction: Interaction) {
        guard let context = modelContext else { return }
        
        if interaction.rid == nil {
            context.delete(interaction)
        } else {
            interaction.syncStatus = .toDelete
        }
        try? context.save()
        
    }
    
    
    func endInteraction(interaction: Interaction){
        guard let context = modelContext else { return }
        do {
            interaction.timeEnd = .now
            interaction.markAsModified()
            try context.save()
        } catch {
            print("Failed to end interaction.")
        }
    }
    
}
