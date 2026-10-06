import Foundation

final class LifeEventTypesService: SupabaseDataService<LifeEventTypeDTO, LifeEventTypePayload> {
    
    init() {
        super.init(tableName: "data_life_event_types")
    }
    
    // MARK: Semantic methods
    
    func fetchTypes(includeArchived: Bool = false) async throws -> [LifeEventTypeDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createType(payload: LifeEventTypePayload) async throws -> LifeEventTypeDTO {
        try await create(payload: payload)
    }
    
    func updateType(rid: Int, payload: LifeEventTypePayload) async throws -> LifeEventTypeDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteType(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
