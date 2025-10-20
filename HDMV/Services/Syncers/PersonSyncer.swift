//
//  PathSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//


import Foundation
import SwiftData


@MainActor
final class PersonSyncer: BaseSyncer<Person, PersonDTO, PersonPayload> {
    
    private let peopleService = PeopleService()
    private let settings: SettingsStore = SettingsStore.shared
        
    override func fetchRemoteModels(date: Date? = nil) async throws -> [PersonDTO] {
        return try await peopleService.fetchPeople(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: PersonPayload) async throws -> PersonDTO {
        return try await peopleService.createPerson(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: PersonPayload) async throws -> PersonDTO {
        return try await peopleService.updatePerson(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Country deletion not implemented")
    }
    
}

