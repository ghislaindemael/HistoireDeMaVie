//
//  InteractionSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData

@MainActor
class InteractionSyncer: BaseLogSyncer<Interaction, InteractionDTO, InteractionPayload> {
    
    private let interactionService = PeopleInteractionsService()

    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date?) async throws -> [InteractionDTO] {
        if let date = date {
            return try await interactionService.fetchInteractions(for: date)
        }
        fatalError("No date passed in fetchRemoteModels")
    }
        
    override func createOnServer(payload: InteractionPayload) async throws -> InteractionDTO {
        return try await interactionService.createInteraction(payload)
    }
    
    override func updateOnServer(rid: Int, payload: InteractionPayload) async throws -> InteractionDTO {
        return try await interactionService.updateInteraction(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        //try await instanceService.deleteActivityInstance(id: id)
    }
    
    override func resolveRelationships() throws {
        print("Resolving Interaction relationships...")
        
        let instanceLookup: [Int: ActivityInstance] = try getLookupMap()
        let peopleLookup: [Int: Person] = try getLookupMap()
        
        try resolveRelationship(
            for: Interaction.self,
            relationshipKeyPath: \Interaction.parentInstance,
            ridKeyPath: \Interaction .parentInstanceRid,
            lookupMap: instanceLookup
        )
        
        try resolveRelationship(
            for: Interaction.self,
            relationshipKeyPath: \Interaction.person,
            ridKeyPath: \Interaction.personRid,
            lookupMap: peopleLookup
        )
        
        print("All Interaction relationships resolved.")
    }

}
