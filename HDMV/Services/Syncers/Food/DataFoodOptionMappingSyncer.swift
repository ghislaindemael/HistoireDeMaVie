import Foundation
import SwiftData

@MainActor
final class DataFoodOptionMappingSyncer: BaseSyncer<DataFoodOptionMapping, DataFoodOptionMappingDTO, DataFoodOptionMappingPayload> {
    
    private let service = DataFoodOptionMappingService()
    
    override func fetchRemoteModels(date: Date?) async throws -> [DataFoodOptionMappingDTO] {
        return try await service.fetchItems()
    }
    
    override func createOnServer(payload: DataFoodOptionMappingPayload) async throws -> DataFoodOptionMappingDTO {
        return try await service.createItem(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataFoodOptionMappingPayload) async throws -> DataFoodOptionMappingDTO {
        return try await service.updateItem(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await service.delete(rid: id)
    }
    
    override func resolveRelationships() throws {
        let mappings = try modelContext.fetch(FetchDescriptor<DataFoodOptionMapping>())
        
        let items = try modelContext.fetch(FetchDescriptor<DataFoodItem>())
        let options = try modelContext.fetch(FetchDescriptor<DataFoodOption>())
        
        let itemDict = Dictionary(uniqueKeysWithValues: items.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil })
        let optionDict = Dictionary(uniqueKeysWithValues: options.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil })
        
        for mapping in mappings {
            if let iid = mapping.foodItemRid, let item = itemDict[iid] {
                if mapping.foodItem?.persistentModelID != item.persistentModelID {
                    mapping.foodItem = item
                }
            }
            if let oid = mapping.foodOptionRid, let opt = optionDict[oid] {
                if mapping.foodOption?.persistentModelID != opt.persistentModelID {
                    mapping.foodOption = opt
                }
            }
        }
        try modelContext.save()
    }
}
