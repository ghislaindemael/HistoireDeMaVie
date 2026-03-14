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