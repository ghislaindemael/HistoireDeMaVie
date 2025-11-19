//
//  PathService.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.11.2025.
//

import Foundation

final class PathService: SupabaseDataService<PathDTO, PathPayload> {
    
    init() {
        super.init(tableName: "data_paths")
    }
    
    // MARK: Semantic methods
    
    func fetchPaths(includeArchived: Bool = false) async throws -> [PathDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createPath(payload: PathPayload) async throws -> PathDTO {
        try await create(payload: payload)
    }
    
    func updatePath(rid: Int, payload: PathPayload) async throws -> PathDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deletePath(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
