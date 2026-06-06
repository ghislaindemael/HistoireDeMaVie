import Foundation

class DataFoodOptionService: SupabaseDataService<DataFoodOptionDTO, DataFoodOptionPayload> {
    init() {
        super.init(tableName: "data_food_options")
    }
    
    func fetchItems() async throws -> [DataFoodOptionDTO] {
        return try await fetch(includeArchived: true, orderColumn: "id")
    }
    
    func createItem(payload: DataFoodOptionPayload) async throws -> DataFoodOptionDTO {
        return try await create(payload: payload)
    }
    
    func updateItem(rid: Int, payload: DataFoodOptionPayload) async throws -> DataFoodOptionDTO {
        return try await update(rid: rid, payload: payload)
    }
}
