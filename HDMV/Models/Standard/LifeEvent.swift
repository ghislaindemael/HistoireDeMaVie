//
//  LifeEvent.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//

import SwiftData
import Foundation

@Model
final class LifeEvent: LogModel {
    
    var rid: Int?
    var typeSlug: String = LifeEventType.unset.rawValue
    var timeStart: Date = Date()
    var timeEnd: Date?
    var details: String?
    var metrics: LifeEventMetrics?
    
    var parentInstanceRid: Int?
    var parentTripRid: Int?

    var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    var type: LifeEventType {
        get { LifeEventType(rawValue: typeSlug) ?? .unset }
        set { typeSlug = newValue.rawValue }
    }
    
    typealias DTO = LifeEventDTO
    typealias Payload = LifeEventPayload
    typealias Editor = LifeEventEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?
    
    // MARK: Init
    
    init(rid: Int? = nil,
         type: LifeEventType? = .unset,
         timeStart: Date = .now,
         timeEnd: Date? = nil,
         details: String? = nil,
         metrics: LifeEventMetrics? = nil,
         parentInstance: ActivityInstance? = nil,
         syncStatus: SyncStatus = .local
    ){
        self.rid = rid
        self.type = type ?? .unset
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.details = details
        self.metrics = metrics
        self.parentInstance = parentInstance
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: LifeEventDTO) {
        self.init()
        self.rid = dto.id
        self.type = dto.type
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.details = dto.details
        self.metrics = dto.metrics
        self.parentInstanceRid = dto.parent_instance_id
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: LifeEventDTO) {
        self.type = dto.type
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.details = dto.details
        self.metrics = dto.metrics 
        self.parentInstanceRid = dto.parent_instance_id
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return true
    }
    
}

struct LifeEventDTO: Identifiable, Codable, Sendable {
    let id: Int
    let type: LifeEventType
    let time_start: Date
    let time_end: Date?
    let details: String?
    let metrics: LifeEventMetrics?
    let parent_instance_id: Int?
}


struct LifeEventPayload: Codable, InitializableWithModel {
    
    let type: LifeEventType
    let time_start: Date
    let time_end: Date?
    let details: String?
    let metrics: LifeEventMetrics?
    let parent_instance_id: Int?
    
    typealias Model = LifeEvent
    
    init?(from event: LifeEvent) {
        guard event.isValid()
        else { return nil }
        
        self.type = event.type
        self.time_start = event.timeStart
        self.time_end = event.timeEnd
        self.details = event.details
        self.metrics = event.metrics
        self.parent_instance_id = event.parentInstanceRid

    }
    
}

struct LifeEventEditor: TimeBound, EditorProtocol {

    var type: LifeEventType
    var timeStart: Date
    var timeEnd: Date?
    var details: String?
    var metrics: LifeEventMetrics
    var parentInstance: ActivityInstance?
    var parentInstanceRid: Int?
    
    typealias Model = LifeEvent
    
    init(from event: LifeEvent) {
        self.type = event.type
        self.timeStart = event.timeStart
        self.timeEnd = event.timeEnd
        self.details = event.details
        self.metrics = event.metrics ?? LifeEventMetrics()
        self.parentInstance = event.parentInstance
        self.parentInstanceRid = event.parentInstanceRid
    }
    
    func apply(to event: LifeEvent) {
        
        event.type = self.type
        event.timeStart = self.timeStart
        event.timeEnd = self.timeEnd
        event.details = self.details
        event.metrics = self.metrics
        event.parentInstance = self.parentInstance
        event.parentInstanceRid = self.parentInstance?.rid
        
        event.markAsModified()
    }
}

