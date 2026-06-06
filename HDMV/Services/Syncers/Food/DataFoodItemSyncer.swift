import Foundation
import SwiftData

@MainActor
final class DataFoodItemSyncer: BaseSyncer<DataFoodItem, DataFoodItemDTO, DataFoodItemPayload> {
    
    private let service = DataFoodItemService()
    
    override func fetchRemoteModels(date: Date?) async throws -> [DataFoodItemDTO] {
        return try await service.fetchItems()
    }
    
    override func createOnServer(payload: DataFoodItemPayload) async throws -> DataFoodItemDTO {
        return try await service.createItem(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataFoodItemPayload) async throws -> DataFoodItemDTO {
        return try await service.updateItem(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("deletion not implemented")
    }
    
    override func resolveRelationships() throws {}
}
