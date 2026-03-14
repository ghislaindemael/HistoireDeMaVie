import Foundation

class PeopleInteractionsService: SupabaseDataService<InteractionDTO, InteractionPayload> {
    
    init() {
        super.init(tableName: "my_people_interactions")
    }
    
    // MARK: - Semantic methods
    
    func fetchInteractions(for date: Date) async throws -> [InteractionDTO] {
        try await fetchForDate(date: date)
    }
    
    func createInteraction(_ payload: InteractionPayload) async throws -> InteractionDTO {
        try await create(payload: payload)
    }
    
    func updateInteraction(id: Int, payload: InteractionPayload) async throws -> InteractionDTO {
        try await update(rid: id, payload: payload)
    }
    
    func deleteInteraction(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
