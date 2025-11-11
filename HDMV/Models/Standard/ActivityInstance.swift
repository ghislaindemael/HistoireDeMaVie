//
//  ActivityInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ActivityInstance: LogModel {
        
    @Attribute(.unique) var rid: Int?
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool = true
    var percentage: Int
    
    var activityRid: Int?
    var parentInstanceRid: Int?
    var parentTripRid: Int?
    
    var details: String?
    var activity_details: Data?
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = ActivityInstanceDTO
    typealias Payload = ActivityInstancePayload
    typealias Editor = ActivityInstanceEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var activity: Activity?
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?
    
    @Relationship(deleteRule: .nullify, inverse: \ActivityInstance.parentInstance)
    var childActivities: [ActivityInstance]? = []
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.parentInstance)
    var childTrips: [Trip]? = nil
    
    @Relationship(deleteRule: .nullify, inverse: \Interaction.parentInstance)
    var childInteractions: [Interaction]? = nil
    
    @Relationship(deleteRule: .nullify, inverse: \LifeEvent.parentInstance)
    var childLifeEvents: [LifeEvent]? = nil
    
    // MARK: Init

    init(
        rid: Int? = nil,
        timeStart: Date = .now,
        timeEnd: Date? = nil,
        timed: Bool = true,
        percentage: Int = 100,
        activityRid: Int? = nil,
        parentRid: Int? = nil,
        details: String? = nil,
        activity_details: ActivityDetails? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.activityRid = activityRid
        self.parentInstanceRid = parentRid
        self.details = details
        self.percentage = percentage
        self.syncStatus = syncStatus
        self.decodedActivityDetails = activity_details
    }
    
    var decodedActivityDetails: ActivityDetails? {
        get {
            guard let data = activity_details else { return nil }
            return try? JSONDecoder().decode(ActivityDetails.self, from: data)
        }
        set {
            activity_details = try? JSONEncoder().encode(newValue)
        }
    }
    
    convenience init(fromDto dto: ActivityInstanceDTO) {
        self.init()
        self.rid = dto.id
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.activityRid = dto.activity_id
        self.parentInstanceRid = dto.parent_instance_id
        self.details = dto.details
        self.percentage = dto.percentage ?? 100
        self.decodedActivityDetails = dto.activity_details
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: ActivityInstanceDTO) {
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.activityRid = dto.activity_id
        self.parentInstanceRid = dto.parent_instance_id
        self.details = dto.details
        self.percentage = dto.percentage ?? 100
        self.decodedActivityDetails = dto.activity_details
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return activityRid != nil
    }
    
}

struct ActivityInstanceDTO: Codable, Identifiable {
    let id: Int
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let parent_instance_id: Int?
    let details: String?
    let percentage: Int?
    let activity_details: ActivityDetails?

}


struct ActivityInstancePayload: Codable, InitializableWithModel {
    
    typealias Model = ActivityInstance
    
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let parent_instance_id: Int?
    let details: String?
    let percentage: Int
    let activity_details: ActivityDetails?

    init?(from instance: ActivityInstance) {
        guard instance.isValid() else {
            print("-> ActivityInstance \(instance.id) is invalid.")
            return nil
        }
        
        self.time_start = instance.timeStart
        self.time_end = instance.timeEnd
        self.activity_id = instance.activityRid
        self.parent_instance_id = instance.parentInstance?.rid
        self.details = instance.details
        self.percentage = instance.percentage
        
        if var details = instance.decodedActivityDetails {
            details.removeFields()
            self.activity_details = details
        } else {
            self.activity_details = nil
        }
    }
}

struct ActivityInstanceEditor: TimeTrackable, EditorProtocol {
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool
    var percentage: Int
    var activity: Activity?
    var parent: ActivityInstance?
    var details: String?
    var decodedActivityDetails: ActivityDetails?
    
    typealias Model = ActivityInstance
    
    /// Initializes an editor from an existing ActivityInstance.
    init(from instance: ActivityInstance) {
        self.timeStart = instance.timeStart
        self.timeEnd = instance.timeEnd
        self.timed = instance.timed
        self.percentage = instance.percentage
        self.activity = instance.activity
        self.parent = instance.parentInstance
        self.details = instance.details
        self.decodedActivityDetails = instance.decodedActivityDetails
    }
    
    func apply(to instance: ActivityInstance) {
        instance.timeStart = self.timeStart
        instance.timeEnd = self.timeEnd
        instance.timed = self.timed
        instance.percentage = self.percentage
        instance.activity = self.activity
        instance.activityRid = self.activity?.rid
        instance.parentInstance = self.parent
        instance.details = self.details
        instance.decodedActivityDetails = self.decodedActivityDetails
    }
    

}
