//
//  DataActivityOptionService.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation

class DataActivityOptionService: SupabaseDataService<DataActivityOptionDTO, DataActivityOptionPayload> {
    
    init() {
        super.init(tableName: "data_activity_options")
    }
    
    func fetchOptions() async throws -> [DataActivityOptionDTO] {
        return try await fetch(includeArchived: true, orderColumn: "name")
    }
    
    func createOption(payload: DataActivityOptionPayload) async throws -> DataActivityOptionDTO {
        return try await create(payload: payload)
    }
    
    func updateOption(rid: Int, payload: DataActivityOptionPayload) async throws -> DataActivityOptionDTO {
        return try await update(rid: rid, payload: payload)
    }
}
