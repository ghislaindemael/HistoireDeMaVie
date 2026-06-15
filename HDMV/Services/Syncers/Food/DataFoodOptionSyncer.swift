import Foundation
import SwiftData

@MainActor
final class DataFoodOptionSyncer: BaseSyncer<DataFoodOption, DataFoodOptionDTO, DataFoodOptionPayload> {
    
    private let service = DataFoodOptionService()
    
    override func fetchRemoteModels(date: Date?) async throws -> [DataFoodOptionDTO] {
        return try await service.fetchItems()
    }
    
    override func createOnServer(payload: DataFoodOptionPayload) async throws -> DataFoodOptionDTO {
        return try await service.createItem(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataFoodOptionPayload) async throws -> DataFoodOptionDTO {
        return try await service.updateItem(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("deletion not implemented")
    }
    
    override func resolveRelationships() throws {}
}
