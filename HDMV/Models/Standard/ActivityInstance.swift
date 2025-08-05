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
    var activity_details: Data?
    var syncStatus: SyncStatus = SyncStatus.undef


    init(
        id: Int,
        time_start: Date,
        time_end: Date? = nil,
        activity_id: Int? = nil,
        details: String? = nil,
        activity_details: ActivityDetails? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.id = id
        self.time_start = time_start
        self.time_end = time_end
        self.activity_id = activity_id
        self.details = details
        self.syncStatus = syncStatus
        self.decodedActivityDetails = activity_details
    }
    
    convenience init(
        fromDto dto: ActivityInstanceDTO
    ){
        self.init(
            id: dto.id,
            time_start: dto.time_start,
            time_end: dto.time_end,
            activity_id: dto.activity_id,
            details: dto.details,
            syncStatus: .synced
        )
        self.decodedActivityDetails = dto.activity_details
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
        self.decodedActivityDetails = dto.activity_details
        self.syncStatus = .synced
    }
    
}

struct ActivityInstanceDTO: Codable, Identifiable {
    let id: Int
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let details: String?
    let activity_details: ActivityDetails?

}


struct ActivityInstancePayload: Codable {
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let details: String?
    let activity_details: ActivityDetails?
}
