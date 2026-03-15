//
//  TransactionTypesService.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//

import Foundation

final class TransactionTypesService: SupabaseDataService<TransactionTypeDTO, TransactionTypePayload> {
    
    init() {
        super.init(tableName: "data_transaction_types")
    }
    
    // MARK: Semantic methods
    
    func fetchTypes(includeArchived: Bool = false) async throws -> [TransactionTypeDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createType(payload: TransactionTypePayload) async throws -> TransactionTypeDTO {
        try await create(payload: payload)
    }
    
    func updateType(rid: Int, payload: TransactionTypePayload) async throws -> TransactionTypeDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteType(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
