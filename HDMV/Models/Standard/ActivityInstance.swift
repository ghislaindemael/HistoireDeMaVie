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
final class ActivityInstance: SyncableModel {
        
    @Attribute(.unique) var rid: Int?
    var time_start: Date
    var time_end: Date?
    var activityRid: Int?
    @Relationship
    var relActivity: Activity? {
        didSet {
            activityRid = relActivity?.rid
        }
    }
    var parentRid: Int?
    var parent: ActivityInstance? {
        didSet {
            parentRid = parent?.rid
        }
    }
    @Relationship(deleteRule: .nullify, inverse: \ActivityInstance.parent)
    var childActivities: [ActivityInstance]? = []
    @Relationship(deleteRule: .nullify, inverse: \Trip.parentInstance)
    var trips: [Trip]? = []
    @Relationship(deleteRule: .nullify, inverse: \PersonInteraction.parentInstance)
    var interactions: [PersonInteraction]? = []
    var details: String?
    var percentage: Int
    var activity_details: Data?
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = ActivityInstanceDTO
    typealias Payload = ActivityInstancePayload
    

    init(
        rid: Int? = nil,
        time_start: Date = .now,
        time_end: Date? = nil,
        activityRid: Int? = nil,
        activity: Activity? = nil,
        parentRid: Int? = nil,
        parent: ActivityInstance? = nil,
        details: String? = nil,
        percentage: Int = 100,
        activity_details: ActivityDetails? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.time_start = time_start
        self.time_end = time_end
        self.activityRid = activityRid
        self.relActivity = activity
        self.parentRid = parentRid
        self.parent = parent
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
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.activityRid = dto.activity_id
        self.parentRid = dto.parent_instance_id
        self.details = dto.details
        self.percentage = dto.percentage ?? 100
        self.decodedActivityDetails = dto.activity_details
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: ActivityInstanceDTO) {
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.activityRid = dto.activity_id
        self.parentRid = dto.parent_instance_id
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
        
        self.time_start = instance.time_start
        self.time_end = instance.time_end
        self.activity_id = instance.activityRid
        self.parent_instance_id = instance.parent?.rid
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

struct ActivityInstanceEditor {
    var time_start: Date
    var time_end: Date?
    var activity: Activity?
    var parent: ActivityInstance?
    var details: String?
    var percentage: Int
    var decodedActivityDetails: ActivityDetails?
    
    /// Initializes an editor from an existing ActivityInstance.
    init(from instance: ActivityInstance) {
        self.time_start = instance.time_start
        self.time_end = instance.time_end
        self.activity = instance.activity
        self.parent = instance.parent
        self.details = instance.details
        self.percentage = instance.percentage
        self.decodedActivityDetails = instance.decodedActivityDetails
    }
    
    func apply(to instance: ActivityInstance) {
        instance.time_start = self.time_start
        instance.time_end = self.time_end
        instance.activity = self.activity
        instance.activityRid = self.activity?.rid
        instance.parent = self.parent
        instance.details = self.details
        instance.percentage = self.percentage
        instance.decodedActivityDetails = self.decodedActivityDetails
        
    }
    

}
