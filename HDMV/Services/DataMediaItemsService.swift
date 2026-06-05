//
//  DataMediaItemsService.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation

final class DataMediaItemsService: SupabaseDataService<DataMediaItemDTO, DataMediaItemPayload> {
    
    init() {
        super.init(tableName: "data_media_items")
    }
    
    // MARK: Semantic methods
    
    func fetchItems(includeArchived: Bool = false) async throws -> [DataMediaItemDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createItem(payload: DataMediaItemPayload) async throws -> DataMediaItemDTO {
        try await create(payload: payload)
    }
    
    func updateItem(rid: Int, payload: DataMediaItemPayload) async throws -> DataMediaItemDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteItem(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
