//
//  AgendaEntrySyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 30.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class AgendaEntrySyncer: BaseSyncer<AgendaEntry, AgendaEntryDTO, AgendaEntryPayload> {
    
    private let agendaService = AgendaEntryService()
    
    override func fetchRemoteModels(date: Date? = nil) async throws -> [AgendaEntryDTO] {
        guard let date = date else { return [] }
        if let dto = try await agendaService.fetchAgendaEntry(for: date) {
            return [dto]
        } else {
            return []
        }
    }
    
    func upsertOnServer(payload: AgendaEntryPayload) async throws -> AgendaEntryDTO {
        return try await agendaService.upsertAgendaEntry(payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("AgendaEntry deletion not implemented")
    }
    
    override func pushChanges() async throws {
        let localItems = try fetchLocalModels(with: SyncStatus.local)
        let failedItems = try fetchLocalModels(with: SyncStatus.failed)
        let itemsToSync = localItems + failedItems
        
        guard !itemsToSync.isEmpty else { return }
        print("AgendaSyncer: Found \(itemsToSync.count) items to push.")
        
        for item in itemsToSync {
            guard let payload = AgendaEntryPayload(from: item) else {
                print("Invalid payload for AgendaEntry: \(item.id)")
                continue
            }
            
            do {
                _ = try await self.upsertOnServer(payload: payload)
                item.syncStatus = .synced
            } catch {
                item.syncStatus = .failed
                print("❌ Failed to sync AgendaEntry \(item.id): \(error)")
            }
        }
        
        try modelContext.save()
    }
    
    override func pullChanges(date: Date?) async throws {
        
        guard let filterDate = date else { throw SyncError.missingDateContext }
        
        let dtos = try await fetchRemoteModels(date: filterDate)
        
        let dayNumber = DayCalculator.dayNumber(for: filterDate)
        let predicate = #Predicate<AgendaEntry> { $0.rid == dayNumber }
        let descriptor = FetchDescriptor<AgendaEntry>(predicate: predicate)
        let localEntry = (try modelContext.fetch(descriptor)).first
        
        if let dto = dtos.first {
            if let existingLocal = localEntry {
                guard existingLocal.syncStatus == .synced else {
                    print("AgendaSyncer: Skipping pull, local entry has changes.")
                    return
                }
                existingLocal.update(fromDto: dto)
            } else {
                let newEntry = AgendaEntry(fromDto: dto)
                modelContext.insert(newEntry)
            }
        } else {
            if let existingLocal = localEntry, existingLocal.syncStatus == .synced {
                print("AgendaSyncer: Pruning local entry for \(filterDate) (deleted from server).")
                modelContext.delete(existingLocal)
            }
        }
        
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
    
}
