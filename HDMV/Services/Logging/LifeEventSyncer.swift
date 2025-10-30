//
//  LifeEventSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//


import Foundation
import SwiftData

@MainActor
class LifeEventSyncer: BaseSyncer<LifeEvent, LifeEventDTO, LifeEventPayload> {
    
    private let eventService = LifeEventService()

    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date?) async throws -> [LifeEventDTO] {
        guard let filterDate = date else {
            print("❌ Error: Date must be provided when fetching LifeEvents.")
            throw SyncError.missingDateContext
        }
        return try await eventService.fetchLifeEvents(for: filterDate)
    }
        
    override func createOnServer(payload: LifeEventPayload) async throws -> LifeEventDTO {
        return try await eventService.createLifeEvent(payload)
    }
    
    override func updateOnServer(rid: Int, payload: LifeEventPayload) async throws -> LifeEventDTO {
        return try await eventService.updateLifeEvent(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        //try await eventService.deleteLifeEvent(id: id)
    }
            
    override func pullChanges(date: Date?) async throws {
        guard let filterDate = date else {
            print("LifeEventSyncer requires a date to pull changes.")
            throw SyncError.missingDateContext
        }
        
        let dtos = try await fetchRemoteModels(date: filterDate)
        let serverRids = Set(dtos.map { $0.id })
        print("LifeEventSyncer: Found \(dtos.count) DTOs from server.")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: filterDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw SyncError.dateCalculationError
        }
        
        let predicate = #Predicate<LifeEvent> {
            $0.timeStart >= startOfDay && $0.timeStart < endOfDay
        }
        let descriptor = FetchDescriptor<LifeEvent>(predicate: predicate)
        let relevantLocalModels = try modelContext.fetch(descriptor)
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        print("LifeEventSyncer: Found \(relevantLocalModels.count) relevant local models.")
        
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
            } else {
                let newModel = LifeEvent(fromDto: dto)
                modelContext.insert(newModel)
            }
        }
        
        let ridsToDelete = localRids.subtracting(serverRids)
        for rid in ridsToDelete {
            if let modelToDelete = localCache[rid], modelToDelete.syncStatus == .synced {
                modelContext.delete(modelToDelete)
            }
        }
        
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    
}
