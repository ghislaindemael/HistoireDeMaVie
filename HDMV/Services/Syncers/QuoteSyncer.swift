//
//  QuoteSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//


import Foundation
import SwiftData

@MainActor
class QuoteSyncer: BaseSyncer<Quote, QuoteDTO, QuotePayload> {
    
    private let quoteService = QuoteService()

    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date?) async throws -> [QuoteDTO] {
        guard let filterDate = date else {
            print("❌ Error: Date must be provided when fetching Quotes.")
            throw SyncError.missingDateContext
        }
        return try await quoteService.fetchQuotes(for: filterDate)
    }
        
    override func createOnServer(payload: QuotePayload) async throws -> QuoteDTO {
        return try await quoteService.createQuote(payload)
    }
    
    override func updateOnServer(rid: Int, payload: QuotePayload) async throws -> QuoteDTO {
        return try await quoteService.updateQuote(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        //try await quoteService.deleteQuote(id: id)
    }
            
    override func pullChanges(date: Date?) async throws {
        guard let filterDate = date else {
            print("QuoteSyncer requires a date to pull changes.")
            throw SyncError.missingDateContext
        }
        
        let dtos = try await fetchRemoteModels(date: filterDate)
        let serverRids = Set(dtos.map { $0.id })
        print("QuoteSyncer: Found \(dtos.count) DTOs from server.")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: filterDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw SyncError.dateCalculationError
        }
        
        let predicate = #Predicate<Quote> {
            $0.timeStart >= startOfDay && $0.timeStart < endOfDay
        }
        let descriptor = FetchDescriptor<Quote>(predicate: predicate)
        let relevantLocalModels = try modelContext.fetch(descriptor)
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        print("QuoteSyncer: Found \(relevantLocalModels.count) relevant local models.")
        
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
            } else {
                let newModel = Quote(fromDto: dto)
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

    override func resolveRelationships() throws {
        print("Resolving Quote relationships...")
        
        let personLookup: [Int: Person] = try getLookupMap()
        let mediaItemLookup: [Int: DataMediaItem] = try getLookupMap()
        let interactionLookup: [Int: Interaction] = try getLookupMap()
        let instanceLookup: [Int: ActivityInstance] = try getLookupMap()
        let tripLookup: [Int: Trip] = try getLookupMap()
                
        try resolveRelationship(
            for: Quote.self,
            relationshipKeyPath: \Quote.person,
            ridKeyPath: \Quote.personRid,
            lookupMap: personLookup
        )
        
        try resolveRelationship(
            for: Quote.self,
            relationshipKeyPath: \Quote.mediaItem,
            ridKeyPath: \Quote.mediaItemRid,
            lookupMap: mediaItemLookup
        )
        
        try resolveRelationship(
            for: Quote.self,
            relationshipKeyPath: \Quote.parentInteraction,
            ridKeyPath: \Quote.parentInteractionRid,
            lookupMap: interactionLookup
        )
        
        try resolveRelationship(
            for: Quote.self,
            relationshipKeyPath: \Quote.parentInstance,
            ridKeyPath: \Quote.parentInstanceRid,
            lookupMap: instanceLookup
        )
        
        try resolveRelationship(
            for: Quote.self,
            relationshipKeyPath: \Quote.parentTrip,
            ridKeyPath: \Quote.parentTripRid,
            lookupMap: tripLookup
        )
        
        print("All Quote relationships resolved.")
    }
}
