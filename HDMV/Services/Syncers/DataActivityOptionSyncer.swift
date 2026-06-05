//
//  DataActivityOptionSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@MainActor
final class DataActivityOptionSyncer: BaseSyncer<DataActivityOption, DataActivityOptionDTO, DataActivityOptionPayload> {
    
    private let optionsService = DataActivityOptionService()
        
    override func fetchRemoteModels(date: Date?) async throws -> [DataActivityOptionDTO] {
        return try await optionsService.fetchOptions()
    }
    
    override func createOnServer(payload: DataActivityOptionPayload) async throws -> DataActivityOptionDTO {
        return try await optionsService.createOption(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataActivityOptionPayload) async throws -> DataActivityOptionDTO {
        return try await optionsService.updateOption(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("DataActivityOption deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        // DataActivityOption has no foreign keys to resolve
    }
}
