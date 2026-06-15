import Foundation

class DataFoodItemService: SupabaseDataService<DataFoodItemDTO, DataFoodItemPayload> {
    init() {
        super.init(tableName: "data_food_items")
    }
    
    func fetchItems() async throws -> [DataFoodItemDTO] {
        return try await fetch(includeArchived: true, orderColumn: "id")
    }
    
    func createItem(payload: DataFoodItemPayload) async throws -> DataFoodItemDTO {
        return try await create(payload: payload)
    }
    
    func updateItem(rid: Int, payload: DataFoodItemPayload) async throws -> DataFoodItemDTO {
        return try await update(rid: rid, payload: payload)
    }
}
