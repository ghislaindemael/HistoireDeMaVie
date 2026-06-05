//
//  DataActivityOptionMappingSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@MainActor
final class DataActivityOptionMappingSyncer: BaseSyncer<DataActivityOptionMapping, DataActivityOptionMappingDTO, DataActivityOptionMappingPayload> {
    
    private let mappingService = DataActivityOptionMappingService()
        
    override func fetchRemoteModels(date: Date?) async throws -> [DataActivityOptionMappingDTO] {
        return try await mappingService.fetchMappings()
    }
    
    override func createOnServer(payload: DataActivityOptionMappingPayload) async throws -> DataActivityOptionMappingDTO {
        return try await mappingService.createMapping(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataActivityOptionMappingPayload) async throws -> DataActivityOptionMappingDTO {
        return try await mappingService.updateMapping(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("DataActivityOptionMapping deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        let allMappings = try modelContext.fetch(FetchDescriptor<DataActivityOptionMapping>())
        
        // Caches for quick lookup
        let activities = try modelContext.fetch(FetchDescriptor<Activity>())
        let activityCache = Dictionary(activities.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil }, uniquingKeysWith: { first, _ in first })
        
        let options = try modelContext.fetch(FetchDescriptor<DataActivityOption>())
        let optionCache = Dictionary(options.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
        
        for mapping in allMappings {
            // Bind Activity
            let targetActivity = activityCache[mapping.activityRid]
            if mapping.activity?.persistentModelID != targetActivity?.persistentModelID {
                mapping.activity = targetActivity
            }
            
            // Bind Option
            let targetOption = optionCache[mapping.optionSlug]
            if mapping.option?.persistentModelID != targetOption?.persistentModelID {
                mapping.option = targetOption
            }
        }
    }
}
