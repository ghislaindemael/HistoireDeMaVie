//
//  TransactionSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import Foundation
import SwiftData

@MainActor
class TransactionSyncer: BaseLogSyncer<Transaction, TransactionDTO, TransactionPayload> {
    
    private let transactionService = TransactionService()

    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date?) async throws -> [TransactionDTO] {
        guard let filterDate = date else {
            print("❌ Error: Date must be provided when fetching Transactions.")
            throw SyncError.missingDateContext
        }
        return try await transactionService.fetchTransactions(for: filterDate)
    }
        
    override func createOnServer(payload: TransactionPayload) async throws -> TransactionDTO {
        return try await transactionService.createTransaction(payload)
    }
    
    override func updateOnServer(rid: Int, payload: TransactionPayload) async throws -> TransactionDTO {
        return try await transactionService.updateTransaction(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await transactionService.deleteTransaction(id: id)
    }
    
    // MARK: - Advanced Synchronization
    
    func pullChanges(transactionTypeRid: Int, startDate: Date, endDate: Date) async throws {
        let dtos = try await transactionService.fetchTransactions(
            transactionTypeId: transactionTypeRid,
            startDate: startDate,
            endDate: endDate
        )
        let serverRids = Set(dtos.map { $0.id })
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            throw SyncError.dateCalculationError
        }
        
        let predicate = #Predicate<Transaction> {
            $0.timeStart < endOfDay && $0.timeStart > startOfDay &&
            $0.typeRid == transactionTypeRid
        }
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        let relevantLocalModels = try modelContext.fetch(descriptor)
        
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
                let newModel = Transaction(fromDto: dto)
                modelContext.insert(newModel)
                insertedCount += 1
            }
        }
        print("PullChanges Advanced (Transaction): Inserted \(insertedCount), Updated \(updatedCount).")
        
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
        print("Resolving Transaction relationships...")
        
        // 1. Fetch Lookup Maps
        let typesLookup: [Int: TransactionType] = try getLookupMap()
        let instancesLookup: [Int: ActivityInstance] = try getLookupMap()
        let peopleLookup: [Int: Person] = try getLookupMap()
        
        // 2. Resolve Transaction Type
        try resolveRelationship(
            for: Transaction.self,
            relationshipKeyPath: \Transaction.type,
            ridKeyPath: \Transaction.typeRid,
            lookupMap: typesLookup
        )
        
        // 3. Resolve Parent Activity Instance
        try resolveRelationship(
            for: Transaction.self,
            relationshipKeyPath: \Transaction.parentInstance,
            ridKeyPath: \Transaction.parentInstanceRid,
            lookupMap: instancesLookup
        )
        
        // 4. Resolve Payer (Person)
        try resolveRelationship(
            for: Transaction.self,
            relationshipKeyPath: \Transaction.payer,
            ridKeyPath: \Transaction.payerRid,
            lookupMap: peopleLookup
        )
        
        // Note: If you have a LifeContext model linked to contextRid, resolve it here too!
        // let contextLookup: [Int: LifeContext] = try getLookupMap()
        // try resolveRelationship(
        //     for: Transaction.self,
        //     relationshipKeyPath: \Transaction.context, 
        //     ridKeyPath: \Transaction.contextRid,
        //     lookupMap: contextLookup
        // )
        
        print("All Transaction relationships resolved.")
    }
}