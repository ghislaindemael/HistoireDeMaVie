import Foundation

class DataFoodOptionMappingService: SupabaseDataService<DataFoodOptionMappingDTO, DataFoodOptionMappingPayload> {
    init() {
        super.init(tableName: "data_food_option_mappings")
    }
    
    func fetchItems() async throws -> [DataFoodOptionMappingDTO] {
        return try await fetch(includeArchived: true, orderColumn: "id")
    }
    
    func createItem(payload: DataFoodOptionMappingPayload) async throws -> DataFoodOptionMappingDTO {
        return try await create(payload: payload)
    }
    
    func updateItem(rid: Int, payload: DataFoodOptionMappingPayload) async throws -> DataFoodOptionMappingDTO {
        return try await update(rid: rid, payload: payload)
    }
}
