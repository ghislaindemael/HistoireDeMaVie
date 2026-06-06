import Foundation

class DataFoodRecipeService: SupabaseDataService<DataFoodRecipeDTO, DataFoodRecipePayload> {
    init() {
        super.init(tableName: "data_food_recipes")
    }
    
    func fetchItems() async throws -> [DataFoodRecipeDTO] {
        return try await fetch(includeArchived: true, orderColumn: "id")
    }
    
    func createItem(payload: DataFoodRecipePayload) async throws -> DataFoodRecipeDTO {
        return try await create(payload: payload)
    }
    
    func updateItem(rid: Int, payload: DataFoodRecipePayload) async throws -> DataFoodRecipeDTO {
        return try await update(rid: rid, payload: payload)
    }
}
