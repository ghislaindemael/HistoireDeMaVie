//
//  PersonInteractionSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData

@MainActor
class PersonInteractionSyncer: BaseSyncer<PersonInteraction, PersonInteractionDTO, PersonInteractionPayload> {
    
    private let interactionService = PeopleInteractionsService()

    // MARK: - Implemented Network Methods
        
    override func createOnServer(payload: PersonInteractionPayload) async throws -> PersonInteractionDTO {
        return try await interactionService.createInteraction(payload)
    }
    
    override func updateOnServer(rid: Int, payload: PersonInteractionPayload) async throws -> PersonInteractionDTO {
        return try await interactionService.updateInteraction(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        //try await instanceService.deleteActivityInstance(id: id)
    }
    

}
