import Foundation
import SwiftData

@MainActor
final class DataFoodRecipeSyncer: BaseSyncer<DataFoodRecipe, DataFoodRecipeDTO, DataFoodRecipePayload> {
    
    private let service = DataFoodRecipeService()
    
    override func fetchRemoteModels(date: Date?) async throws -> [DataFoodRecipeDTO] {
        return try await service.fetchItems()
    }
    
    override func createOnServer(payload: DataFoodRecipePayload) async throws -> DataFoodRecipeDTO {
        return try await service.createItem(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataFoodRecipePayload) async throws -> DataFoodRecipeDTO {
        return try await service.updateItem(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("deletion not implemented")
    }
    
    override func resolveRelationships() throws {}
}
