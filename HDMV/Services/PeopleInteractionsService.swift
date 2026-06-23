import Foundation

class PeopleInteractionsService: SupabaseDataService<InteractionDTO, InteractionPayload> {
    
    init() {
        super.init(tableName: "my_people_interactions")
    }
    
    // MARK: - Semantic methods
    
    func fetchInteractions(for date: Date) async throws -> [InteractionDTO] {
        try await fetchForDate(date: date)
    }
    
    func fetchInteractions(personId: Int, startDate: Date, endDate: Date) async throws -> [InteractionDTO] {
        guard let supabaseClient = supabaseClient else { return [] }
        
        let formatter = ISO8601DateFormatter()
        let query = supabaseClient
            .from(tableName)
            .select()
            .contains("person_ids", value: [personId])
            .gte("time_start", value: formatter.string(from: startDate))
            .lt("time_start", value: formatter.string(from: endDate))
            
        return try await query
            .order("time_start", ascending: false)
            .execute()
            .value
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
