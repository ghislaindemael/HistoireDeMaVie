//
//  LifeContextSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//


import Foundation
import SwiftData


@MainActor
final class LifeContextSyncer: BaseSyncer<LifeContext, LifeContextDTO, LifeContextPayload> {
    
    private let contextsService = LifeContextsService()
    private let settings: SettingsStore = SettingsStore.shared
        
    override func fetchRemoteModels(date: Date?) async throws -> [LifeContextDTO] {
        return try await contextsService.fetchContexts(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: LifeContextPayload) async throws -> LifeContextDTO {
        return try await contextsService.createContext(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: LifeContextPayload) async throws -> LifeContextDTO {
        return try await contextsService.updateContext(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        try await contextsService.deleteContext(id: id)
    }
    
    override func resolveRelationships() throws {
        let allContexts = try modelContext.fetch(FetchDescriptor<LifeContext>())
        let modelsWithRid = allContexts.filter { $0.rid != nil }
        
        let contextCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) },
                                      uniquingKeysWith: { (first, _) in first })
        
        for context in allContexts {
            guard let parentRid = context.parentRid else {
                if context.parent != nil {
                    context.parent = nil
                }
                continue
            }
            
            if context.parent?.rid != parentRid {
                context.parent = contextCache[parentRid]
            }
        }
    }
}
