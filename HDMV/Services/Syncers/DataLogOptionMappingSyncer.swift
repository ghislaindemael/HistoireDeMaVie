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
        
    override func fetchRemoteModels(date: Date?) async throws -> [DataLogOptionMappingDTO] {
        return try await mappingService.fetchMappings()
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
