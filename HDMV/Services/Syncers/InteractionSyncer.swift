import Foundation
import SwiftData

@MainActor
class InteractionSyncer: BaseLogSyncer<Interaction, InteractionDTO, InteractionPayload> {
    
    private let interactionService = PeopleInteractionsService()
    
    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date?) async throws -> [InteractionDTO] {
        if let date = date {
            return try await interactionService.fetchInteractions(for: date)
        }
        fatalError("No date passed in fetchRemoteModels")
    }
    
    override func createOnServer(payload: InteractionPayload) async throws -> InteractionDTO {
        return try await interactionService.createInteraction(payload)
    }
    
    override func updateOnServer(rid: Int, payload: InteractionPayload) async throws -> InteractionDTO {
        return try await interactionService.updateInteraction(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await interactionService.deleteInteraction(id: id)
    }
    
    // MARK: - Advanced Synchronization
    
    func pullChanges(personRid: Int, startDate: Date, endDate: Date) async throws {
        let dtos = try await interactionService.fetchInteractions(
            personId: personRid,
            startDate: startDate,
            endDate: endDate
        )
        let serverRids = Set(dtos.map { $0.id })
        
        let future = Date.distantFuture
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            throw SyncError.dateCalculationError
        }
        
        let predicate = #Predicate<Interaction> {
            $0.timeStart < endOfDay && ($0.timeEnd ?? future) > startOfDay
        }
        let descriptor = FetchDescriptor<Interaction>(predicate: predicate)
        var relevantLocalModels = try modelContext.fetch(descriptor)
        
        // Filter by personRids in memory to avoid SwiftData SQLite translation crash (EXC_BAD_ACCESS)
        relevantLocalModels = relevantLocalModels.filter { $0.personRids.contains(personRid) }
        
        let modelsWithRid = relevantLocalModels.filter { $0.rid != nil }
        let localCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) }, uniquingKeysWith: { (first, _) in return first })
        let localRids = Set(localCache.keys)
        
        var insertedCount = 0
        var updatedCount = 0
        
        for dto in dtos {
            if let existingModel = localCache[dto.id] {
                guard existingModel.syncStatus == .synced else { continue }
                existingModel.update(fromDto: dto)
                updatedCount += 1
            } else {
                let newModel = Interaction(fromDto: dto)
                modelContext.insert(newModel)
                insertedCount += 1
            }
        }
        print("PullChanges Advanced (Interaction): Inserted \(insertedCount), Updated \(updatedCount).")
        
        let ridsToDelete = localRids.subtracting(serverRids)
        for rid in ridsToDelete {
            if let modelToDelete = localCache[rid], modelToDelete.syncStatus == .synced {
                modelContext.delete(modelToDelete)
            }
        }
        
        try resolveRelationships()
        if modelContext.hasChanges { try modelContext.save() }
    }
    
    // MARK: - Relationship Resolution
    
    override func resolveRelationships() throws {
        print("Resolving Interaction relationships...")
        
        let instanceLookup: [Int: ActivityInstance] = try getLookupMap()
        let peopleLookup: [Int: Person] = try getLookupMap()
        let tripLookup: [Int: Trip] = try getLookupMap()
        
        try resolveRelationship(
            for: Interaction.self,
            relationshipKeyPath: \Interaction.parentTrip,
            ridKeyPath: \Interaction.parentTripRid,
            lookupMap: tripLookup
        )
        
        try resolveRelationship(
            for: Interaction.self,
            relationshipKeyPath: \Interaction.parentInstance,
            ridKeyPath: \Interaction .parentInstanceRid,
            lookupMap: instanceLookup
        )
        
        try resolveToManyRelationship(
            for: Interaction.self,
            relationshipKeyPath: \Interaction.persons,
            ridArrayKeyPath: \Interaction.personRids,
            lookupMap: peopleLookup
        )
        
        print("All Interaction relationships resolved.")
    }
}
