//
//  DataLogOptionMappingService.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation

class DataLogOptionMappingService: SupabaseDataService<DataLogOptionMappingDTO, DataLogOptionMappingPayload> {
    
    init() {
        super.init(tableName: "data_log_option_mappings")
    }
    
    func fetchMappings() async throws -> [DataLogOptionMappingDTO] {
        return try await fetch(includeArchived: true, orderColumn: "priority")
    }
    
    func createMapping(payload: DataLogOptionMappingPayload) async throws -> DataLogOptionMappingDTO {
        return try await create(payload: payload)
    }
    
    func updateMapping(rid: Int, payload: DataLogOptionMappingPayload) async throws -> DataLogOptionMappingDTO {
        return try await update(rid: rid, payload: payload)
    }
}
