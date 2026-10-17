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
        var ridsToDeleteFromServer: [Int] = []
        
        let allOptions = try modelContext.fetch(FetchDescriptor<DataLogOption>())
        let optionMap = Dictionary(allOptions.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
        
        for mapping in allMappings {
            let hasTarget = mapping.activity != nil || mapping.activityRid != nil ||
                mapping.vehicle != nil || mapping.vehicleRid != nil ||
                mapping.vehicleTypeSlug != nil ||
                mapping.transactionType != nil || mapping.transactionTypeRid != nil ||
                mapping.lifeEventType != nil || mapping.lifeEventTypeRid != nil
            
            if !hasTarget {
                // Delete legacy targetless mapping locally immediately
                if let rid = mapping.rid {
                    ridsToDeleteFromServer.append(rid)
                }
                modelContext.delete(mapping)
                didModify = true
                continue
            }
            
            // Sync foreign RIDs if the model reference is set but RID is missing
            if mapping.activityRid == nil, let rid = mapping.activity?.rid {
                mapping.activityRid = rid
                didModify = true
            }
            if mapping.vehicleRid == nil, let rid = mapping.vehicle?.rid {
                mapping.vehicleRid = rid
                didModify = true
            }
            if mapping.transactionTypeRid == nil, let rid = mapping.transactionType?.rid {
                mapping.transactionTypeRid = rid
                didModify = true
            }
            if mapping.lifeEventTypeRid == nil, let rid = mapping.lifeEventType?.rid {
                mapping.lifeEventTypeRid = rid
                didModify = true
            }
            
            // Check attached option
            let matchingOption = mapping.option ?? optionMap[mapping.optionSlug]
            if let option = matchingOption, option.slug.isNotUnset() && option.slug != "!unset" {
                if mapping.option?.persistentModelID != option.persistentModelID {
                    mapping.option = option
                    didModify = true
                }
                if mapping.optionSlug != option.slug {
                    mapping.optionSlug = option.slug
                    didModify = true
                }
            } else if matchingOption == nil {
                // Orphaned mapping whose option doesn't exist anymore locally
                print("⚠️ DataLogOptionMappingSyncer: Removing orphaned mapping for missing option '\(mapping.optionSlug)'")
                if let rid = mapping.rid {
                    ridsToDeleteFromServer.append(rid)
                }
                modelContext.delete(mapping)
                didModify = true
                continue
            }
        }
        
        if didModify {
            try? modelContext.save()
        }
        
        // Asynchronously delete targetless or orphaned mappings from server without stalling UI thread
        if !ridsToDeleteFromServer.isEmpty {
            Task.detached(priority: .background) { [mappingService] in
                for rid in ridsToDeleteFromServer {
                    _ = try? await mappingService.delete(rid: rid)
                }
            }
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
        
        let lifeEventTypes = try modelContext.fetch(FetchDescriptor<LifeEventType>())
        let lifeEventTypeCache = Dictionary(lifeEventTypes.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil }, uniquingKeysWith: { first, _ in first })
        
        let options = try modelContext.fetch(FetchDescriptor<DataLogOption>())
        let optionCache = Dictionary(options.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
        
        var didModify = false
        for mapping in allMappings {
            // Bind Activity
            let targetActivity = mapping.activityRid.flatMap { activityCache[$0] }
            if mapping.activity?.persistentModelID != targetActivity?.persistentModelID {
                mapping.activity = targetActivity
                didModify = true
            }
            
            // Bind Vehicle
            let targetVehicle = mapping.vehicleRid.flatMap { vehicleCache[$0] }
            if mapping.vehicle?.persistentModelID != targetVehicle?.persistentModelID {
                mapping.vehicle = targetVehicle
                didModify = true
            }
            
            // Bind TransactionType
            let targetTxType = mapping.transactionTypeRid.flatMap { txTypeCache[$0] }
            if mapping.transactionType?.persistentModelID != targetTxType?.persistentModelID {
                mapping.transactionType = targetTxType
                didModify = true
            }
            
            // Bind LifeEventType
            let targetLifeEventType = mapping.lifeEventTypeRid.flatMap { lifeEventTypeCache[$0] }
            if mapping.lifeEventType?.persistentModelID != targetLifeEventType?.persistentModelID {
                mapping.lifeEventType = targetLifeEventType
                didModify = true
            }
            
            // Bind Option
            let targetOption = optionCache[mapping.optionSlug]
            if mapping.option?.persistentModelID != targetOption?.persistentModelID {
                mapping.option = targetOption
                didModify = true
            }
        }
        
        if didModify {
            try? modelContext.save()
        }
    }
}
