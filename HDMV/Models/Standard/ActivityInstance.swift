//
//  ActivityInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import Foundation
import SwiftData

@Model
final class ActivityInstance {
    @Attribute(.unique) var id: Int
    var time_start: Date
    var time_end: Date?
    var activity_id: Int?
    var details: String?
    var syncStatus: SyncStatus = SyncStatus.undef

    init(id: Int, time_start: Date, time_end: Date? = nil, activity_id: Int? = nil, details: String? = nil, syncStatus: SyncStatus = .local) {
        self.id = id
        self.time_start = time_start
        self.time_end = time_end
        self.activity_id = activity_id
        self.details = details
        self.syncStatus = syncStatus
    }
    
    init(fromDto dto: ActivityInstanceDTO){
        self.id = dto.id
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.activity_id = dto.activity_id
        self.details = dto.details
        self.syncStatus = .synced
    }
}

struct ActivityInstanceDTO: Codable, Identifiable {
    let id: Int
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let details: String?
}


struct ActivityInstancePayload: Codable {
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let details: String?
}
