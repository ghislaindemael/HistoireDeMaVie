//
//  DataActivityOptionMapping.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

@Model
final class DataActivityOptionMapping: Identifiable, Hashable, CatalogueModel {
    
    var rid: Int?
    var activityRid: Int?
    var isForTrip: Bool = false
    var optionSlug: String
    var priority: Int
    var required: Bool = false
    var cache: Bool = true
    var archived: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    // Relationships
    var activity: Activity?
    var option: DataActivityOption?
    
    typealias Payload = DataActivityOptionMappingPayload
    typealias DTO = DataActivityOptionMappingDTO
    typealias Editor = DataActivityOptionMappingEditor
    
    init(
        rid: Int? = nil,
        activityRid: Int? = nil,
        isForTrip: Bool = false,
        optionSlug: String = "",
        priority: Int = 0,
        required: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.activityRid = activityRid
        self.isForTrip = isForTrip
        self.optionSlug = optionSlug
        self.priority = priority
        self.required = required
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: DataActivityOptionMappingDTO) {
        self.init()
        self.rid = dto.id
        self.activityRid = dto.activity_id
        self.isForTrip = dto.is_for_trip ?? false
        self.optionSlug = dto.option_slug
        self.priority = dto.priority
        self.required = dto.required ?? false
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataActivityOptionMappingDTO) {
        self.activityRid = dto.activity_id
        self.isForTrip = dto.is_for_trip ?? false
        self.optionSlug = dto.option_slug
        self.priority = dto.priority
        self.required = dto.required ?? false
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return (activityRid != nil || isForTrip) && !optionSlug.isEmpty
    }
    
    var hasUnsyncedChanges: Bool {
        return self.syncStatus != .synced
    }
}

// MARK: - DTO and Payload

struct DataActivityOptionMappingDTO: Codable, Identifiable {
    let id: Int
    let activity_id: Int?
    let is_for_trip: Bool?
    let option_slug: String
    let priority: Int
    let required: Bool?
}

struct DataActivityOptionMappingPayload: Codable, InitializableWithModel {
    typealias Model = DataActivityOptionMapping
    
    let activity_id: Int?
    let is_for_trip: Bool
    let option_slug: String
    let priority: Int
    let required: Bool
    
    init?(from model: DataActivityOptionMapping) {
        guard model.isValid() else { return nil }
        self.activity_id = model.activityRid
        self.is_for_trip = model.isForTrip
        self.option_slug = model.optionSlug
        self.priority = model.priority
        self.required = model.required
    }
}

struct DataActivityOptionMappingEditor: CachableModel, EditorProtocol {
    var activity: Activity?
    var activityRid: Int?
    var isForTrip: Bool = false
    var option: DataActivityOption?
    var optionSlug: String
    var priority: Int
    var required: Bool = false
    var cache: Bool = true
    var archived: Bool = false
    
    typealias Model = DataActivityOptionMapping
    
    init(from model: DataActivityOptionMapping) {
        self.activity = model.activity
        self.activityRid = model.activityRid
        self.isForTrip = model.isForTrip
        self.option = model.option
        self.optionSlug = model.optionSlug
        self.priority = model.priority
        self.required = model.required
        self.cache = model.cache
        self.archived = model.archived
    }
    
    func apply(to model: DataActivityOptionMapping) {
        model.activity = self.activity
        model.activityRid = self.activityRid
        model.isForTrip = self.isForTrip
        model.option = self.option
        model.optionSlug = self.optionSlug
        model.priority = self.priority
        model.required = self.required
        model.cache = self.cache
        model.archived = self.archived
    }
}

extension DataActivityOptionMapping: Equatable {
    static func == (lhs: DataActivityOptionMapping, rhs: DataActivityOptionMapping) -> Bool {
        lhs.id == rhs.id
    }
}
