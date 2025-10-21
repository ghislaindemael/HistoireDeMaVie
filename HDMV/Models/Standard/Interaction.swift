//
//  Interaction.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation
import SwiftData

// MARK: - SwiftData Model
@Model
final class Interaction: Equatable, SyncableModel {
        
    @Attribute(.unique) var rid: Int?
    var time_start: Date = Date()
    var time_end: Date?
    var timed: Bool = true
    var in_person: Bool = true
    var personRid: Int?
    @Relationship
    var person: Person? {
        didSet {
            personRid = person?.rid
        }
    }
    var percentage: Int?
    var parentInstanceRid: Int?
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance? {
        didSet {
            parentInstanceRid = parentInstance?.rid
        }
    }
    var details: String?
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = InteractionDTO
    typealias Payload = InteractionPayload

    init(
        rid: Int? = nil,
        time_start: Date = .now,
        time_end: Date? = nil,
        timed: Bool = true,
        parentInstance: ActivityInstance? = nil,
        person: Person? = nil,
        in_person: Bool = true,
        details: String? = nil,
        percentage: Int? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.rid = rid
        self.time_start = time_start
        self.time_end = time_end
        self.timed = timed
        self.parentInstance = parentInstance
        self.person = person
        self.in_person = in_person
        self.details = details
        self.percentage = percentage
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: InteractionDTO) {
        self.init()
        
        self.rid = dto.id
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.parentInstanceRid = dto.parent_activity_id
        self.personRid = dto.person_id
        self.timed = dto.timed
        self.in_person = dto.in_person
        self.details = dto.details
        self.percentage = dto.percentage
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: InteractionDTO) {
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.parentInstanceRid = dto.parent_activity_id
        self.personRid = dto.person_id
        self.timed = dto.timed
        self.in_person = dto.in_person
        self.details = dto.details
        self.percentage = dto.percentage
        
        if self.person?.rid != self.personRid { self.person = nil }
        if self.parentInstance?.rid != self.parentInstanceRid { self.parentInstance = nil }
    }
    
    // MARK: - Computed properties
    
    var isStandalone: Bool {
        parentInstance == nil
    }
    
    /// Checks if the interaction is valid for syncing.
    /// An interaction needs to have a person linked, and either be attached to an activity instance
    /// or have it's own start time
    func isValid() -> Bool {
        guard self.personRid != nil else { return false }
        
        return true
    }
    
}

// MARK: - DTOs for Network

struct InteractionDTO: Codable, Identifiable, Sendable {
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


struct InteractionPayload: Codable, InitializableWithModel {
    
    typealias Model = Interaction
    
    var time_start: Date?
    var time_end: Date?
    var parent_instance_id: Int?
    var person_id: Int?
    var timed: Bool
    var in_person: Bool
    var details: String?
    var percentage: Int?
        
    /// Creates a payload directly from a Interaction model object.
    /// This is the primary initializer you'll use in your ViewModel.
    init(from interaction: Interaction) {
        self.time_start = interaction.time_start
        self.time_end = interaction.time_end
        self.parent_instance_id = interaction.parentInstanceRid
        self.person_id = interaction.personRid
        self.timed = interaction.timed
        self.in_person = interaction.in_person
        self.details = interaction.details
        self.percentage = interaction.percentage
    }
}


struct InteractionEditor {
    
    var time_start: Date
    var time_end: Date?
    var timed: Bool
    var in_person: Bool
    var details: String?
    var percentage: Int?
    
    var personRid: Int?
    var person: Person?
    
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance?
    
    
    // MARK: - Derived flags
    
    /// Indicates if the linked person record might be archived or missing.
    var isPersonArchived: Bool {
        person == nil && personRid != nil
    }
    
    /// Indicates if this editor has a linked parent activity.
    var hasParent: Bool {
        parentInstance != nil || parentInstanceRid != nil
    }
    
    // MARK: - Init from model
    
    init(interaction: Interaction) {
        self.time_start = interaction.time_start
        self.time_end = interaction.time_end
        self.timed = interaction.timed
        self.in_person = interaction.in_person
        self.details = interaction.details
        self.percentage = interaction.percentage
        
        self.person = interaction.person
        self.personRid = interaction.personRid
        self.parentInstance = interaction.parentInstance
        self.parentInstanceRid = interaction.parentInstanceRid
    }
    
    // MARK: - Apply back to model
    
    func apply(to interaction: Interaction) {
        interaction.time_start = self.time_start
        interaction.time_end = self.time_end
        interaction.timed = self.timed
        interaction.in_person = self.in_person
        interaction.details = self.details
        interaction.percentage = self.percentage
        
        interaction.person = self.person
        interaction.personRid = self.person?.rid

        interaction.parentInstance = self.parentInstance
        interaction.parentInstanceRid = self.parentInstance?.rid
        
        interaction.markAsModified()
    }
}
