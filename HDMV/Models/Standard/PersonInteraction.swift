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
final class PersonInteraction: Equatable, Identifiable, SyncableModel {
    @Attribute(.unique) var id: Int
    var time_start: Date
    var time_end: Date?
    var parent_activity_id: Int?
    var person_id: Int?
    var timed: Bool = true
    var in_person: Bool = true
    var details: String?
    var percentage: Int?
    var syncStatus: SyncStatus = SyncStatus.undef
    
    init(id: Int,
         time_start: Date = .now,
         time_end: Date? = nil,
         parent_activity_id: Int? = nil,
         person_id: Int? = nil,
         timed: Bool = true,
         in_person: Bool = true,
         details: String? = nil,
         percentage: Int? = nil,
         syncStatus: SyncStatus = .local
    ) {
        self.id = id
        self.time_start = time_start
        self.time_end = time_end
        self.parent_activity_id = parent_activity_id
        self.person_id = person_id
        self.timed = timed
        self.in_person = in_person
        self.details = details
        self.percentage = percentage
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: PersonInteractionDTO) {
        self.init(
            id: dto.id,
            time_start: dto.time_start,
            time_end: dto.time_end,
            parent_activity_id: dto.parent_activity_id,
            person_id: dto.person_id,
            timed: dto.timed,
            in_person: dto.in_person,
            details: dto.details,
            percentage: dto.percentage,
            syncStatus: .synced
        )
    }
    
    func update(fromDto dto: PersonInteractionDTO) {
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.parent_activity_id = dto.parent_activity_id
        self.person_id = dto.person_id
        self.timed = dto.timed
        self.in_person = dto.in_person
        self.details = dto.details
        self.percentage = dto.percentage
    }
    
    // MARK: - Computed properties
    
    var isStandalone: Bool {
        parent_activity_id == nil
    }
    
    /// Checks if the interaction is valid for syncing.
    /// An interaction needs to have a person linked, and either be attached to an activity instance
    /// or have it's own start time
    func isValid() -> Bool {
        guard self.person_id != nil else { return false }
        
        return time_end != nil
    }
    
}

// MARK: - DTOs for Network

struct PersonInteractionDTO: Codable, Identifiable, Sendable {
    var id: Int
    var time_start: Date
    var time_end: Date?
    var parent_activity_id: Int?
    var person_id: Int
    var timed: Bool
    var in_person: Bool
    var details: String?
    var percentage: Int?
}


struct PersonInteractionPayload: Encodable {
    var time_start: Date?
    var time_end: Date?
    var parent_activity_id: Int?
    var person_id: Int?
    var timed: Bool
    var in_person: Bool
    var details: String?
    var percentage: Int?
        
    /// Creates a payload directly from a PersonInteraction model object.
    /// This is the primary initializer you'll use in your ViewModel.
    init(from interaction: PersonInteraction) {
        self.time_start = interaction.time_start
        self.time_end = interaction.time_end
        self.parent_activity_id = interaction.parent_activity_id
        self.person_id = interaction.person_id
        self.timed = interaction.timed
        self.in_person = interaction.in_person
        self.details = interaction.details
        self.percentage = interaction.percentage
    }
}
