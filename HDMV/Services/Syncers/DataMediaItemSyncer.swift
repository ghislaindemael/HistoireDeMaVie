//
//  DataMediaItemSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation
import SwiftData

@MainActor
final class DataMediaItemSyncer: BaseSyncer<DataMediaItem, DataMediaItemDTO, DataMediaItemPayload> {
    
    private let itemsService = DataMediaItemsService()
    private let settings: SettingsStore = SettingsStore.shared
        
    override func fetchRemoteModels(date: Date?) async throws -> [DataMediaItemDTO] {
        return try await itemsService.fetchItems(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: DataMediaItemPayload) async throws -> DataMediaItemDTO {
        return try await itemsService.createItem(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataMediaItemPayload) async throws -> DataMediaItemDTO {
        return try await itemsService.updateItem(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await itemsService.deleteItem(id: id)
    }
    
    override func resolveRelationships() throws {
        let allItems = try modelContext.fetch(FetchDescriptor<DataMediaItem>())
        let modelsWithRid = allItems.filter { $0.rid != nil }
        
        let itemCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) },
                                      uniquingKeysWith: { (first, _) in first })
        
        for item in allItems {
            guard let parentRid = item.parentRid else {
                if item.parent != nil {
                    item.parent = nil
                }
                continue
            }
            
            if item.parent?.rid != parentRid {
                item.parent = itemCache[parentRid]
            }
        }
    }
}
