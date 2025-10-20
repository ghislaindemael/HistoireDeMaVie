//
//  PeopleService.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation


final class PeopleService: SupabaseDataService<PersonDTO, PersonPayload> {
    
    init() {
        super.init(tableName: "data_people")
    }
    
    // MARK: Semantic methods
    
    func fetchPeople(includeArchived: Bool = false) async throws -> [PersonDTO] {
        guard let client = supabaseClient else { throw URLError(.cannotConnectToHost) }
        var query = client.from(tableName).select()
        if !includeArchived {
            query = query.eq("archived", value: false)
        }
        
        let response = try await query.order("name", ascending: true).execute()
        let data = response.data
        
        let decoder = JSONDecoder()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let people = try decoder.decode([PersonDTO].self, from: data)
            return people
        } catch {
            print("❌ PersonDTO decoding failed: \(error)")
            if let decodingError = error as? DecodingError { print("Details: \(decodingError)") }
            throw error
        }
    }
    
    func createPerson(payload: PersonPayload) async throws -> PersonDTO {
        try await create(payload: payload)
    }
    
    func updatePerson(rid: Int, payload: PersonPayload) async throws -> PersonDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deletePerson(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
