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
        fatalError("DataLogOption deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        // DataLogOption has no foreign keys to resolve
    }
}
