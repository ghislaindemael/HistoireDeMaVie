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
    
    typealias Payload = ActivityInstancePayload
    
    @Attribute(.unique) var id: Int
    var time_start: Date
    var time_end: Date?
    var activity_id: Int?
    var parent: ActivityInstance?
    @Relationship(deleteRule: .nullify, inverse: \ActivityInstance.parent)
    var children: [ActivityInstance]? = []
    var details: String?
    var percentage: Int?
    var activity_details: Data?
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue


    init(
        id: Int,
        time_start: Date,
        time_end: Date? = nil,
        activity_id: Int? = nil,
        parent: ActivityInstance? = nil,
        details: String? = nil,
        percentage: Int? = nil,
        activity_details: ActivityDetails? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.id = id
        self.time_start = time_start
        self.time_end = time_end
        self.activity_id = activity_id
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
    
    func update(fromDto dto: ActivityInstanceDTO) {
        self.id = dto.id
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.activity_id = dto.activity_id
        self.details = dto.details
        self.percentage = dto.percentage
        self.decodedActivityDetails = dto.activity_details
        self.syncStatus = .synced
    }
    
    func update(from editor: ActivityInstanceEditor) {
        self.time_start = editor.time_start
        self.time_end = editor.time_end
        self.activity_id = editor.activity_id
        self.parent = editor.parent
        self.details = editor.details
        self.percentage = editor.percentage
        self.decodedActivityDetails = editor.decodedActivityDetails
    }
        
    func isValid() -> Bool {
        return activity_id != nil
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
    let percentage: Int?
    let activity_details: ActivityDetails?

    init?(from instance: ActivityInstance) {
        guard instance.isValid() else {
            print("-> ActivityInstance \(instance.id) is invalid.")
            return nil
        }
        
        self.time_start = instance.time_start
        self.time_end = instance.time_end
        self.activity_id = instance.activity_id
        self.parent_instance_id = instance.parent?.id
        self.details = instance.details
        self.percentage = instance.percentage
        self.activity_details = instance.decodedActivityDetails
    }
}

struct ActivityInstanceEditor {
    var time_start: Date
    var time_end: Date?
    var activity_id: Int?
    var parent: ActivityInstance?
    var details: String?
    var percentage: Int?
    var decodedActivityDetails: ActivityDetails?
    
    /// Initializes an editor from an existing ActivityInstance.
    init(from instance: ActivityInstance) {
        self.time_start = instance.time_start
        self.time_end = instance.time_end
        self.activity_id = instance.activity_id
        self.parent = instance.parent 
        self.details = instance.details
        self.percentage = instance.percentage
        self.decodedActivityDetails = instance.decodedActivityDetails
    }
}
