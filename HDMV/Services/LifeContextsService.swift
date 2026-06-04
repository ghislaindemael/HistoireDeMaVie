//
//  LifeContextsService.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation

final class LifeContextsService: SupabaseDataService<LifeContextDTO, LifeContextPayload> {
    
    init() {
        super.init(tableName: "my_life_contexts")
    }
    
    // MARK: Semantic methods
    
    func fetchContexts(includeArchived: Bool = false) async throws -> [LifeContextDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createContext(payload: LifeContextPayload) async throws -> LifeContextDTO {
        try await create(payload: payload)
    }
    
    func updateContext(rid: Int, payload: LifeContextPayload) async throws -> LifeContextDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteContext(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
