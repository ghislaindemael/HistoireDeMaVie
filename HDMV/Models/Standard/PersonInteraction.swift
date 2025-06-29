//
//  PersonInteraction.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation
import SwiftData

// MARK: - SwiftData Model
@Model
final class PersonInteraction: @unchecked Sendable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var date: Date
    var time_start: Date
    var time_end: Date?
    var person_id: Int
    var in_person: Bool
    var details: String?
    var percentage: Int
    var syncStatus: SyncStatus = SyncStatus.undef
    
    init(id: Int, date: Date, time_start: Date, time_end: Date? = nil,
         person_id: Int, in_person: Bool, details: String?, percentage: Int, syncStatus: SyncStatus = .local) {
        self.id = id
        self.date = date
        self.time_start = time_start
        self.time_end = time_end
        self.person_id = person_id
        self.in_person = in_person
        self.details = details
        self.percentage = percentage
        self.syncStatus = syncStatus
    }
    
    init(fromDTO dto: PersonInteractionDTO) {
        self.id = dto.id
        self.date = dto.date
        self.time_start = combineDateTime(date: dto.date, timeString: dto.time_start)
        if let timeEndStr = dto.time_end {
            self.time_end = combineDateTime(date: dto.date, timeString: timeEndStr)
        } else {
            self.time_end = nil
        }
        self.person_id = dto.person_id
        self.in_person = dto.in_person
        self.details = dto.details
        self.percentage = dto.percentage
        self.syncStatus = SyncStatus.synced
    }
    
}

// MARK: - DTOs for Network

struct PersonInteractionDTO: Codable, Identifiable, Sendable {
    var id: Int
    var date: Date
    var time_start: String
    var time_end: String?
    var person_id: Int
    var in_person: Bool
    var details: String?
    var percentage: Int
    
}

struct NewPersonInteractionPayload: Encodable {
    var date: Date
    var time_start: String
    var time_end: String?
    var person_id: Int
    var in_person: Bool
    var details: String?
    var percentage: Int
    
    init() {
        self.date = .now
        self.time_start = DateFormatter.timeOnly.string(from: .now)
        self.time_end = nil
        self.person_id = -1
        self.in_person = true
        self.details = nil
        self.percentage = 100
    }
    
    init(date: Date, time_start: String, time_end: String? = nil,
         person_id: Int, in_person: Bool, details: String?, percentage: Int) {
        self.date = date
        self.time_start = time_start
        self.time_end = time_end
        self.person_id = person_id
        self.in_person = in_person
        self.details = details
        self.percentage = percentage
    }
}
