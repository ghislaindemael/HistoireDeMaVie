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
class PeopleInteractionsPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private let interactionService = PeopleInteractionsService()
    @Published var isLoading: Bool = false
    
    @Published var selectedDate: Date = .now
    @Published var interactions: [PersonInteraction] = []
    
    @Published var people: [Person] = []
    
    var hasLocalChanges: Bool {
        interactions.contains { $0.syncStatus != .synced }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchCatalogueData()
    }
    
    // MARK: - Data Fetching
    
    func fetchInteractions() {
        self.interactions = fetchLocalInteractions()
    }
    
    private func fetchLocalInteractions() -> [PersonInteraction] {
        guard let context = modelContext else { return [] }

        
        do {

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
            let future = Date.distantFuture
            
            let predicate = #Predicate<PersonInteraction> {
                $0.time_start < endOfDay &&
                ($0.time_end ?? future) > startOfDay
            }
            let descriptor = FetchDescriptor<PersonInteraction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.time_start, order: .reverse)]
            )
                        
            return try context.fetch(descriptor)
        } catch {
            print("Error during interaction fetch: \(error)")
            return []
        }
    }
        
    private func fetchCatalogueData() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Person>(sortBy: [
                SortDescriptor(\.familyName, order: .forward),
                SortDescriptor(\.name, order: .forward)
            ])
            self.people = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch people: \(error)")
        }
    }
    
    // MARK: Transmitted data
    
    func findPerson(by id:Int?) -> Person? {
        guard let id = id else { return nil }
        return people.first { $0.id == id }
    }

    
    // MARK: - Core Synchronization Logic
    
    func syncWithServer() async {
        isLoading = true
        defer { isLoading = false }
        await syncInteractions()
    }
    
    private func syncInteractions() async {
        guard let context = modelContext else { return }
        
        do {
            let localInteractions = fetchLocalInteractions()
            let onlineInteractions = try await interactionService.fetchInteractions(for: selectedDate)
            
            let onlineDict = Dictionary(uniqueKeysWithValues: onlineInteractions.map { ($0.id, $0) })
            let localDict = Dictionary(uniqueKeysWithValues: localInteractions.map { ($0.id, $0) })
            
            let onlineIDs = Set(onlineDict.keys)
            let localIDs = Set(localDict.keys)
            
            let idsToDelete = localIDs.subtracting(onlineIDs)
            for id in idsToDelete {
                if let interactionToDelete = localDict[id], interactionToDelete.syncStatus == .synced {
                    context.delete(interactionToDelete)
                }
            }
            
            for onlineInteraction in onlineInteractions {
                if let localInteraction = localDict[onlineInteraction.id] {
                    if localInteraction.syncStatus == .synced {
                        localInteraction.update(fromDto: onlineInteraction)
                    }
                } else {
                    context.insert(PersonInteraction(fromDto: onlineInteraction))
                }
            }
            
            if context.hasChanges {
                try context.save()
            }
            
            self.interactions = fetchLocalInteractions()
            sortInteractions()
            
        } catch {
            print("Error during interaction sync: \(error)")
        }
    }

    
    func syncChanges() async {
        guard let context = modelContext else { return }
        
        let interactionsToSync = self.interactions.filter { $0.syncStatus != .synced && $0.syncStatus != .toDelete}
        
        guard !interactionsToSync.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await withTaskGroup(of: Void.self) { group in
            for interaction in interactionsToSync {
                group.addTask {
                    await self.sync(interaction: interaction, in: context)
                }
            }
        }
        
        try? context.save()
    }
    
    private func sync(interaction: PersonInteraction, in context: ModelContext) async {
        guard interaction.isValid() else { return }
        let payload = PersonInteractionPayload(from: interaction)
        do {
            if interaction.id < 0 {
                let newDTO = try await self.interactionService.createInteraction(payload)
                interaction.id = newDTO.id
            } else {
                _ = try await self.interactionService.updatePersonInteraction(id: interaction.id, payload: payload)
            }
            interaction.syncStatus = .synced
        } catch {
            interaction.syncStatus = .failed
            print("Failed to sync interaction \(interaction.id): \(error).")
        }
    }
    
    // MARK: User Actions
        
    func deleteInteraction(_ interaction: PersonInteraction) {
        guard let context = modelContext else { return }
        
        if interaction.id < 0 {
            context.delete(interaction)
        } else {
            interaction.syncStatus = .toDelete
        }
        
        try? context.save()

    }
    
    func generateTempID() -> Int {
        let minExistingID = interactions.map(\.id).filter { $0 < 0 }.min() ?? 0
        return minExistingID - 1
    }
    
    func endPersonInteraction(interaction: PersonInteraction){
        guard let context = modelContext else { return }
        do {
            interaction.time_end = .now
            interaction.syncStatus = .local
            try context.save()
        } catch {
            print("Failed to end interaction.")
        }
    }
    
    func createNewInteractionInCache() {
        guard let context = modelContext else { return }
        let newInteraction =
            PersonInteraction(
                id: generateTempID(),
                time_start: .now,
                person_id: 0,
                in_person: true,
                details: nil,
                percentage: 100)
        
        context.insert(newInteraction)
        do {
            try context.save()
            self.interactions.append(newInteraction)
        } catch {
            print("Failed to create interaction: \(error)")
        }
    }
    
    func createNewInteractionAtNoonInCache() {
        guard let context = modelContext else { return }
        let noonOnSelectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let newInteraction =
        PersonInteraction(
            id: generateTempID(),
            time_start: noonOnSelectedDate,
            person_id: 0,
            in_person: true,
            details: nil,
            percentage: 100)
        context.insert(newInteraction)
        do {
            try context.save()
            self.interactions.append(newInteraction)
            sortInteractions()
        } catch {
            print("Failed to save new interaction at noon: \(error)")
        }
    }
    
    /// Sorts the local `interactions` array, handling both standalone and activity-linked items.
    private func sortInteractions() {
        self.interactions.sort {
            ($0.time_start) < ($1.time_start)
        }
    }
        
    
}
