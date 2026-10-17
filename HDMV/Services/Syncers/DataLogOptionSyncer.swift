//
//  DataLogOptionSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@MainActor
final class DataLogOptionSyncer: BaseSyncer<DataLogOption, DataLogOptionDTO, DataLogOptionPayload> {
    
    private let optionsService = DataLogOptionService()
    
    override func pushChanges() async throws {
        // Enforce slug uniqueness before pushing to remote
        let allOptions = try modelContext.fetch(FetchDescriptor<DataLogOption>())
        var seenSlugs = Set<String>()
        var didModify = false
        for option in allOptions {
            guard !option.archived, option.isValid() else { continue }
            let slug = option.slug.trimmingCharacters(in: .whitespacesAndNewlines)
            if seenSlugs.contains(slug) {
                print("⚠️ DataLogOptionSyncer: Duplicate slug '\(slug)' detected for option \(option.id). Marking as failed.")
                option.syncStatus = .failed
                didModify = true
            } else {
                seenSlugs.insert(slug)
            }
        }
        if didModify {
            try? modelContext.save()
        }
        
        try await super.pushChanges()
    }
        
    override func fetchRemoteModels(date: Date?) async throws -> [DataLogOptionDTO] {
        return try await optionsService.fetchOptions()
    }
    
    override func createOnServer(payload: DataLogOptionPayload) async throws -> DataLogOptionDTO {
        return try await optionsService.createOption(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataLogOptionPayload) async throws -> DataLogOptionDTO {
        return try await optionsService.updateOption(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await optionsService.delete(rid: id)
    }
    
    override func resolveRelationships() throws {
        // DataLogOption has no foreign keys to resolve
    }
}
