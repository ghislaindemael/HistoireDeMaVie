//
//  DataActivityOptionMappingService.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation

class DataActivityOptionMappingService: SupabaseDataService<DataActivityOptionMappingDTO, DataActivityOptionMappingPayload> {
    
    init() {
        super.init(tableName: "data_activity_option_mappings")
    }
    
    func fetchMappings() async throws -> [DataActivityOptionMappingDTO] {
        return try await fetch(includeArchived: true, orderColumn: "priority")
    }
    
    func createMapping(payload: DataActivityOptionMappingPayload) async throws -> DataActivityOptionMappingDTO {
        return try await create(payload: payload)
    }
    
    func updateMapping(rid: Int, payload: DataActivityOptionMappingPayload) async throws -> DataActivityOptionMappingDTO {
        return try await update(rid: rid, payload: payload)
    }
}
