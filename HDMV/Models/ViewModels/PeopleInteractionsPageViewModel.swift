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
    
    @Published var selectedDate: Date = .now
    @Published var allInteractions: [PersonInteraction] = []
    @Published var isLoading: Bool = false
    
    private var interactionService: PeopleInteractionsService = PeopleInteractionsService()
    private var onlineInteractions: [PersonInteraction] = []
    private var localInteractions: [PersonInteraction] = []
    
    var hasLocalInteractions: Bool {
        localInteractions.contains { $0.syncStatus != .synced }
    }
    
    init() {}
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        Task {
            await loadData()
        }
    }
    
    // MARK: - Data Flow Orchestration
    
    func loadData() async {
        isLoading = true
        await fetchOnlineInteractions()
        fetchLocalInteractions()
        mergeInteractions()
        isLoading = false
    }
    
    private func fetchOnlineInteractions() async {
        do {
            self.onlineInteractions = try await interactionService.fetchInteractions(for: selectedDate)
        } catch {
            print("Failed to fetch online trips. Showing local changes only. Error: \(error)")
            self.onlineInteractions = []
        }
    }
    
    private func fetchLocalInteractions() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        do {
            let descriptor = FetchDescriptor<PersonInteraction>(
                predicate: #Predicate { interaction in
                    interaction.date >= startOfDay && interaction.date < endOfDay
                },
                sortBy: [
                    SortDescriptor(\.time_start),
                    SortDescriptor(\.person_id)
                ]
            )
            self.localInteractions = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }

    
    private func mergeInteractions() {
        let combined = localInteractions + onlineInteractions
        
        var seenIDs = Set<Int>()
        let unique = combined.filter { interaction in
            if seenIDs.contains(interaction.id) {
                return false
            } else {
                seenIDs.insert(interaction.id)
                return true
            }
        }
        
        self.allInteractions = unique.sorted {
            if $0.time_start == $1.time_start {
                return $0.person_id < $1.person_id
            } else {
                return $0.time_start < $1.time_start
            }
        }
    }

    
    
    // MARK: User actions
    
    func syncChanges() async {
        guard let context = modelContext else { return }
        
        let dirty = localInteractions.filter {
            $0.syncStatus == .local || $0.syncStatus == .failed
        }
        
        for local in dirty {
            do {
                guard local.person_id != 0 else {
                    local.syncStatus = .failed
                    context.insert(local)
                    continue
                }
                
                local.syncStatus = .syncing
                if local.id < 0 {
                    let payload = NewPersonInteractionPayload(
                        date: local.date,
                        time_start: DateFormatter.timeOnly.string(from: local.time_start),
                        time_end: local.time_end.map { DateFormatter.timeOnly.string(from: $0) },
                        person_id: local.person_id,
                        in_person: local.in_person,
                        details: local.details,
                        percentage: local.percentage
                    )
                    let inserted = try await interactionService.insertInteraction(payload: payload)
                    context.delete(local)
                    onlineInteractions.append(inserted)
                    localInteractions.removeAll { $0.id == local.id }
                } else {
                    let updated = try await interactionService.updateInteraction(interaction: local)
                    updated.syncStatus = .synced
                    context.delete(local)
                    localInteractions.removeAll { $0.id == local.id }
                    onlineInteractions.append(updated)
                }
            } catch {
                print("❌ Full sync error: \(error)")
                local.syncStatus = .failed
                localInteractions.removeAll { $0.id == local.id }
                context.delete(local)
                context.insert(local)
                localInteractions.append(local)
            }
        }
        
        await loadData()
    }
    
    func generateTempID() -> Int {
        let minExistingID = localInteractions
            .map { $0.id }
            .filter { $0 < 0 }
            .min() ?? 0
        return minExistingID - 1
    }

    
    func updateInteraction(_ interaction: PersonInteraction) {
        guard let context = modelContext else { return }
        
        if interaction.syncStatus == .synced {
            // 1. Remove from onlineInteractions and localInteractions + context
            onlineInteractions.removeAll { $0.id == interaction.id }
            
            if let index = localInteractions.firstIndex(where: { $0.id == interaction.id }) {
                context.delete(localInteractions[index])
                localInteractions.remove(at: index)
            }
            
            // 2. Mutate the original instance's syncStatus directly
            interaction.syncStatus = .local
            
            // 3. Insert the same (mutated) instance to localInteractions and context
            context.insert(interaction)
            localInteractions.append(interaction)
            
        } else {
            // For local/fail cases, replace the existing entry with the new one
            if let index = localInteractions.firstIndex(where: { $0.id == interaction.id }) {
                context.delete(localInteractions[index])
                localInteractions.remove(at: index)
            }
            context.insert(interaction)
            localInteractions.append(interaction)
        }
        
        mergeInteractions()
        
        Task {
            await syncChanges()
        }
    }

}
