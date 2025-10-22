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
    
    enum FilterMode: Hashable {
        case byDate
        case byPerson
    }
    
    private var modelContext: ModelContext?
    private var interactionSyncer: InteractionSyncer?
    private var settings: SettingsStore = SettingsStore.shared
    
    @Published var isLoading: Bool = false
    
    @Published var filterMode: FilterMode = .byDate
    @Published var filterDate: Date = .now
    
    @Published var interactions: [Interaction] = []
        
    var hasLocalChanges: Bool {
        interactions.contains { $0.syncStatus != .synced }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.interactionSyncer = InteractionSyncer(modelContext: modelContext)
    }
    
    // MARK: - Data Fetching
    
    func fetchInteractions() {
        guard let context = modelContext else { return }
        
        do {
            
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
        } catch {
            print("Error during interaction fetch: \(error)")
            self.interactions = []
        }
    }

    
    // MARK: - Core Synchronization Logic
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await interactionSyncer?.pullChanges(date: filterDate)
        } catch {
            print("Failed to sync interactions: \(error)")
        }
        fetchInteractions()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await interactionSyncer?.pushChanges()
        } catch {
            print("MasterSyncer changes upload failed: \(error)")
        }
        fetchInteractions()
    }
    
    // MARK: User Actions
        
    func createInteraction(date: Date? = nil) {
        guard let context = modelContext else { return }
        let newInteraction = Interaction(
            time_start: date ?? .now
        )
        context.insert(newInteraction)
        do {
            try context.save()
            self.interactions.append(newInteraction)
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
