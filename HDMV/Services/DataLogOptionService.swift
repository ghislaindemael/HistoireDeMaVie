//
//  DataLogOptionService.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation

class DataLogOptionService: SupabaseDataService<DataLogOptionDTO, DataLogOptionPayload> {
    
    init() {
        super.init(tableName: "data_log_options")
    }
    
    func fetchOptions() async throws -> [DataLogOptionDTO] {
        return try await fetch(includeArchived: true, orderColumn: "name")
    }
    
    func createOption(payload: DataLogOptionPayload) async throws -> DataLogOptionDTO {
        return try await create(payload: payload)
    }
    
    func updateOption(rid: Int, payload: DataLogOptionPayload) async throws -> DataLogOptionDTO {
        return try await update(rid: rid, payload: payload)
    }
}
