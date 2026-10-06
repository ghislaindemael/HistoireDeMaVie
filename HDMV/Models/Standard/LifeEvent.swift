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
    
    @Attribute(.unique) var rid: Int?
    var timeStart: Date = Date()
    var timeEnd: Date?
    var details: String?
    
    var typeRid: Int?
    var parentInstanceRid: Int?
    var parentTripRid: Int?
    var contextRids: [Int] = []

    var log_details: Data?
    
    var decodedLogDetails: LogDetails? {
        get {
            guard let data = log_details else { return nil }
            return try? JSONDecoder().decode(LogDetails.self, from: data)
        }
        set {
            log_details = try? JSONEncoder().encode(newValue)
        }
    }
    
    var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = LifeEventDTO
    typealias Payload = LifeEventPayload
    typealias Editor = LifeEventEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var type: LifeEventType?
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?
    
    // MARK: Init
    
    init(rid: Int? = nil,
         type: LifeEventType? = nil,
         timeStart: Date = .now,
         timeEnd: Date? = nil,
         details: String? = nil,
         parentInstance: ActivityInstance? = nil,
         contextRids: [Int] = [],
         syncStatus: SyncStatus = .unsynced
    ){
        self.rid = rid
        self.type = type
        self.typeRid = type?.rid
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.details = details
        self.parentInstance = parentInstance
        self.contextRids = contextRids
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: LifeEventDTO) {
        self.init()
        self.rid = dto.id
        self.typeRid = dto.type_id
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.details = dto.details
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.contextRids = dto.context_ids ?? []
        self.decodedLogDetails = dto.log_details
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: LifeEventDTO) {
        self.typeRid = dto.type_id
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.details = dto.details
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.contextRids = dto.context_ids ?? []
        self.decodedLogDetails = dto.log_details
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return true
    }
    
}

struct LifeEventDTO: Identifiable, Codable, Sendable {
    let id: Int
    let type_id: Int?
    let time_start: Date
    let time_end: Date?
    let details: String?
    let parent_instance_id: Int?
    let parent_trip_id: Int?
    let context_ids: [Int]?
    let log_details: LogDetails?
}


struct LifeEventPayload: Codable, InitializableWithModel {
    
    let type_id: Int?
    let time_start: Date
    let time_end: Date?
    let details: String?
    @ExplicitNull var parent_instance_id: Int?
    @ExplicitNull var parent_trip_id: Int?
    var context_ids: [Int]
    let log_details: LogDetails?
    
    typealias Model = LifeEvent
    
    init?(from event: LifeEvent) {
        guard event.isValid()
        else { return nil }
        
        self.type_id = event.type?.rid ?? event.typeRid
        self.time_start = event.timeStart
        self.time_end = event.timeEnd
        self.details = event.details
        self.parent_instance_id = event.parentInstanceRid
        self.parent_trip_id = event.parentTripRid
        self.context_ids = event.contextRids
        
        if var details = event.decodedLogDetails {
            details.removeFields()
            self.log_details = details
        } else {
            self.log_details = nil
        }
    }
    
}

struct LifeEventEditor: TimeBound, EditorProtocol, LinkedParent {

    var type: LifeEventType?
    var typeRid: Int?
    var timeStart: Date
    var timeEnd: Date?
    var details: String?
    var log_details: LogDetails?
    var parentInstance: ActivityInstance?
    var parentInstanceRid: Int?
    var parentTrip: Trip?
    var parentTripRid: Int?
    var contextRids: [Int] = []
    
    typealias Model = LifeEvent
    
    init(from event: LifeEvent) {
        self.type = event.type
        self.typeRid = event.typeRid
        self.timeStart = event.timeStart
        self.timeEnd = event.timeEnd
        self.details = event.details
        self.log_details = event.decodedLogDetails
        self.parentInstance = event.parentInstance
        self.parentInstanceRid = event.parentInstanceRid
        self.parentTrip = event.parentTrip
        self.parentTripRid = event.parentTripRid
        self.contextRids = event.contextRids
    }
    
    func apply(to event: LifeEvent) {
        
        event.type = self.type
        event.typeRid = self.type?.rid ?? self.typeRid
        event.timeStart = self.timeStart
        event.timeEnd = self.timeEnd
        event.details = self.details
        event.decodedLogDetails = self.log_details
        event.parentInstance = self.parentInstance
        event.parentInstanceRid = self.parentInstance?.rid ?? self.parentInstanceRid
        event.parentTrip = self.parentTrip
        event.parentTripRid = self.parentTrip?.rid ?? self.parentTripRid
        event.contextRids = self.contextRids
        
        event.markAsModified()
    }
}

extension LifeEvent {
    @discardableResult
    static func create(in context: ModelContext, date: Date) -> LifeEvent {
        let smartDate = date.smartCreationTime
        let newEvent = LifeEvent(timeStart: smartDate, timeEnd: smartDate)
        context.insert(newEvent)
        try? context.save()
        return newEvent
    }
}


