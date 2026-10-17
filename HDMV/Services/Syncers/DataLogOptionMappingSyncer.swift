//
//  DataLogOptionMappingSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@MainActor
final class DataLogOptionMappingSyncer: BaseSyncer<DataLogOptionMapping, DataLogOptionMappingDTO, DataLogOptionMappingPayload> {
    
    private let mappingService = DataLogOptionMappingService()
    
    override func pushChanges() async throws {
        let allMappings = try modelContext.fetch(FetchDescriptor<DataLogOptionMapping>())
        var didModify = false
        for mapping in allMappings {
            let hasTarget = mapping.activity != nil || mapping.activityRid != nil ||
                mapping.vehicle != nil || mapping.vehicleRid != nil ||
                mapping.vehicleTypeSlug != nil ||
                mapping.transactionType != nil || mapping.transactionTypeRid != nil ||
                mapping.lifeEventType != nil || mapping.lifeEventTypeRid != nil
            
            if !hasTarget {
                // Delete legacy targetless mapping without altering option config
                if let rid = mapping.rid {
                    try? await self.deleteFromServer(rid)
                }
                modelContext.delete(mapping)
                didModify = true
                continue
            }
            
            if let option = mapping.option, option.slug.isNotUnset() && option.slug != "!unset" {
                if mapping.optionSlug != option.slug {
                    mapping.optionSlug = option.slug
                    didModify = true
                }
            }
        }
        if didModify {
            try? modelContext.save()
        }
        try await super.pushChanges()
    }
        
    override func fetchRemoteModels(date: Date?) async throws -> [DataLogOptionMappingDTO] {
        let dtos = try await mappingService.fetchMappings()
        // Ignore any legacy remote mappings without an entity or vehicle-type target
        return dtos.filter { dto in
            dto.activity_id != nil ||
            dto.vehicle_id != nil ||
            dto.vehicle_type_slug != nil ||
            dto.transaction_type_id != nil ||
            dto.life_event_type_id != nil
        }
    }
    
    override func createOnServer(payload: DataLogOptionMappingPayload) async throws -> DataLogOptionMappingDTO {
        return try await mappingService.createMapping(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataLogOptionMappingPayload) async throws -> DataLogOptionMappingDTO {
        return try await mappingService.updateMapping(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        _ = try await mappingService.delete(rid: id)
    }
    
    override func resolveRelationships() throws {
        let allMappings = try modelContext.fetch(FetchDescriptor<DataLogOptionMapping>())
        
        // Caches for quick lookup
        let activities = try modelContext.fetch(FetchDescriptor<Activity>())
        let activityCache = Dictionary(activities.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil }, uniquingKeysWith: { first, _ in first })
        
        let vehicles = try modelContext.fetch(FetchDescriptor<Vehicle>())
        let vehicleCache = Dictionary(vehicles.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil }, uniquingKeysWith: { first, _ in first })
        
        let txTypes = try modelContext.fetch(FetchDescriptor<TransactionType>())
        let txTypeCache = Dictionary(txTypes.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil }, uniquingKeysWith: { first, _ in first })
        
        let options = try modelContext.fetch(FetchDescriptor<DataLogOption>())
        let optionCache = Dictionary(options.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
        
        for mapping in allMappings {
            // Bind Activity
            if let activityRid = mapping.activityRid {
                mapping.activity = activityCache[activityRid]
            } else {
                mapping.activity = nil
            }
            
            // Bind Vehicle
            if let vehicleRid = mapping.vehicleRid {
                mapping.vehicle = vehicleCache[vehicleRid]
            } else {
                mapping.vehicle = nil
            }
            
            // Bind TransactionType
            if let transactionTypeRid = mapping.transactionTypeRid {
                mapping.transactionType = txTypeCache[transactionTypeRid]
            } else {
                mapping.transactionType = nil
            }
            
            // Bind Option
            let targetOption = optionCache[mapping.optionSlug]
            if mapping.option?.persistentModelID != targetOption?.persistentModelID {
                mapping.option = targetOption
            }
        }
    }
}
