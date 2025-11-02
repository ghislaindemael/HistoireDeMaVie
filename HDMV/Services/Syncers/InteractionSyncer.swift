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
        let allInteractions = try modelContext.fetch(FetchDescriptor<Interaction>())
        let allPeople = try modelContext.fetch(FetchDescriptor<Person>())
        let allInstances = try modelContext.fetch(FetchDescriptor<ActivityInstance>())
        
        let peopleCache: [Int: Person] = allPeople.reduce(into: [:]) { dict, person in
            if let rid = person.rid {
                dict[rid] = person
            }
        }
        
        let instanceCache: [Int: ActivityInstance] = allInstances.reduce(into: [:]) { dict, instance in
            if let rid = instance.rid {
                dict[rid] = instance
            }
        }
        
        for interaction in allInteractions {
            if let personRid = interaction.personRid {
                let correctPerson = peopleCache[personRid]
                if interaction.person?.rid != personRid {
                    interaction.person = correctPerson
                }
            } else if interaction.person != nil {
                interaction.person = nil
            }
            
            if let parentRid = interaction.parentInstanceRid {
                let correctInstance = instanceCache[parentRid]
                if interaction.parentInstance?.rid != parentRid {
                    interaction.parentInstance = correctInstance
                }
            } else if interaction.parentInstance != nil {
                interaction.parentInstance = nil
            }
        }
        
        print("✅ Relationships resolved for \(allInteractions.count) interactions.")
    }

}
