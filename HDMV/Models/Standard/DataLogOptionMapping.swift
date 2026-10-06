//
//  DataLogOptionMapping.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@Model
final class DataLogOptionMapping: Identifiable, Hashable, CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    var activityRid: Int?
    var vehicleRid: Int?
    var vehicleTypeSlug: String?
    var transactionTypeRid: Int?
    var lifeEventTypeRid: Int?
    var isForInteraction: Bool = false
    var isForTransaction: Bool = false
    var isForLifeEvent: Bool = false
    
    var optionSlug: String
    var priority: Int
    var required: Bool = false
    var cache: Bool = true
    var archived: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    // Relationships
    @Relationship(deleteRule: .nullify) var activity: Activity?
    @Relationship(deleteRule: .nullify) var vehicle: Vehicle?
    @Relationship(deleteRule: .nullify) var transactionType: TransactionType?
    @Relationship(deleteRule: .nullify) var lifeEventType: LifeEventType?
    var option: DataLogOption?
    
    typealias Payload = DataLogOptionMappingPayload
    typealias DTO = DataLogOptionMappingDTO
    typealias Editor = DataLogOptionMappingEditor
    
    init(
        rid: Int? = nil,
        activityRid: Int? = nil,
        vehicleRid: Int? = nil,
        vehicleTypeSlug: String? = nil,
        transactionTypeRid: Int? = nil,
        lifeEventTypeRid: Int? = nil,
        isForInteraction: Bool = false,
        isForTransaction: Bool = false,
        isForLifeEvent: Bool = false,
        optionSlug: String = "",
        priority: Int = 0,
        required: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.activityRid = activityRid
        self.vehicleRid = vehicleRid
        self.vehicleTypeSlug = vehicleTypeSlug
        self.transactionTypeRid = transactionTypeRid
        self.lifeEventTypeRid = lifeEventTypeRid
        self.isForInteraction = isForInteraction
        self.isForTransaction = isForTransaction
        self.isForLifeEvent = isForLifeEvent
        self.optionSlug = optionSlug
        self.priority = priority
        self.required = required
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: DataLogOptionMappingDTO) {
        self.init()
        self.rid = dto.id
        self.activityRid = dto.activity_id
        self.vehicleRid = dto.vehicle_id
        self.vehicleTypeSlug = dto.vehicle_type_slug
        self.transactionTypeRid = dto.transaction_type_id
        self.lifeEventTypeRid = dto.life_event_type_id
        self.isForInteraction = dto.is_for_interaction
        self.isForTransaction = dto.is_for_transaction ?? false
        self.isForLifeEvent = dto.is_for_life_event ?? false
        self.optionSlug = dto.option_slug
        self.priority = dto.priority
        self.required = dto.required ?? false
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataLogOptionMappingDTO) {
        self.activityRid = dto.activity_id
        self.vehicleRid = dto.vehicle_id
        self.vehicleTypeSlug = dto.vehicle_type_slug
        self.transactionTypeRid = dto.transaction_type_id
        self.lifeEventTypeRid = dto.life_event_type_id
        self.isForInteraction = dto.is_for_interaction
        self.isForTransaction = dto.is_for_transaction ?? false
        self.isForLifeEvent = dto.is_for_life_event ?? false
        self.optionSlug = dto.option_slug
        self.priority = dto.priority
        self.required = dto.required ?? false
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        let targets = [
            activityRid != nil,
            vehicleRid != nil,
            vehicleTypeSlug != nil,
            transactionTypeRid != nil,
            lifeEventTypeRid != nil,
            isForInteraction,
            isForLifeEvent,
            isForTransaction
        ]
        return targets.filter { $0 }.count == 1 && !optionSlug.isEmpty
    }
    
    var hasUnsyncedChanges: Bool {
        return self.syncStatus != .synced
    }
}

// MARK: - DTO and Payload

struct DataLogOptionMappingDTO: Codable, Identifiable {
    let id: Int
    let activity_id: Int?
    let vehicle_id: Int?
    let vehicle_type_slug: String?
    let transaction_type_id: Int?
    let life_event_type_id: Int?
    let is_for_interaction: Bool
    let is_for_transaction: Bool?
    let is_for_life_event: Bool?
    
    let option_slug: String
    let priority: Int
    let required: Bool?
}

struct DataLogOptionMappingPayload: Codable, InitializableWithModel {
    typealias Model = DataLogOptionMapping
    
    let activity_id: Int?
    let vehicle_id: Int?
    let vehicle_type_slug: String?
    let transaction_type_id: Int?
    let life_event_type_id: Int?
    let is_for_interaction: Bool
    let is_for_transaction: Bool
    let is_for_life_event: Bool
    
    let option_slug: String
    let priority: Int
    let required: Bool
    
    init?(from model: DataLogOptionMapping) {
        guard model.isValid() else { return nil }
        self.activity_id = model.activityRid
        self.vehicle_id = model.vehicleRid
        self.vehicle_type_slug = model.vehicleTypeSlug
        self.transaction_type_id = model.transactionTypeRid
        self.life_event_type_id = model.lifeEventTypeRid
        self.is_for_interaction = model.isForInteraction
        self.is_for_transaction = model.isForTransaction
        self.is_for_life_event = model.isForLifeEvent
        self.option_slug = model.optionSlug
        self.priority = model.priority
        self.required = model.required
    }
}

struct DataLogOptionMappingEditor: CachableModel, EditorProtocol {
    var activity: Activity?
    var activityRid: Int?
    
    var vehicle: Vehicle?
    var vehicleRid: Int?
    var vehicleTypeSlug: String?
    
    var transactionType: TransactionType?
    var transactionTypeRid: Int?
    
    var lifeEventType: LifeEventType?
    var lifeEventTypeRid: Int?
    
    var isForInteraction: Bool = false
    var isForTransaction: Bool = false
    var isForLifeEvent: Bool = false
    
    var option: DataLogOption?
    var optionSlug: String
    var priority: Int
    var required: Bool = false
    var cache: Bool = true
    var archived: Bool = false
    
    typealias Model = DataLogOptionMapping
    
    init(from model: DataLogOptionMapping) {
        self.activity = model.activity
        self.activityRid = model.activityRid
        
        self.vehicle = model.vehicle
        self.vehicleRid = model.vehicleRid
        self.vehicleTypeSlug = model.vehicleTypeSlug
        
        self.transactionType = model.transactionType
        self.transactionTypeRid = model.transactionTypeRid
        
        self.lifeEventType = model.lifeEventType
        self.lifeEventTypeRid = model.lifeEventTypeRid
        
        self.isForInteraction = model.isForInteraction
        self.isForTransaction = model.isForTransaction
        self.isForLifeEvent = model.isForLifeEvent
        
        self.option = model.option
        self.optionSlug = model.optionSlug
        self.priority = model.priority
        self.required = model.required
        self.cache = model.cache
        self.archived = model.archived
    }
    
    func apply(to model: DataLogOptionMapping) {
        model.activity = self.activity
        model.activityRid = self.activityRid
        
        model.vehicle = self.vehicle
        model.vehicleRid = self.vehicleRid
        model.vehicleTypeSlug = self.vehicleTypeSlug
        
        model.transactionType = self.transactionType
        model.transactionTypeRid = self.transactionTypeRid
        
        model.lifeEventType = self.lifeEventType
        model.lifeEventTypeRid = self.lifeEventTypeRid
        
        model.isForInteraction = self.isForInteraction
        model.isForTransaction = self.isForTransaction
        model.isForLifeEvent = self.isForLifeEvent
        
        model.option = self.option
        model.optionSlug = self.optionSlug
        model.priority = self.priority
        model.required = self.required
        model.cache = self.cache
        model.archived = self.archived
    }
}

extension DataLogOptionMapping: Equatable {
    static func == (lhs: DataLogOptionMapping, rhs: DataLogOptionMapping) -> Bool {
        lhs.id == rhs.id
    }
}
