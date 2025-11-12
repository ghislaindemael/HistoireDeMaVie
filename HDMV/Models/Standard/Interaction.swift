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
final class Interaction: LogModel {
        
    @Attribute(.unique) var rid: Int?
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool = true
    var percentage: Int = 100
    var inPerson: Bool = true
    var personRid: Int?
    
    var parentInstanceRid: Int?
    var parentTripRid: Int?
    
    
    var details: String?
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = InteractionDTO
    typealias Payload = InteractionPayload
    typealias Editor = InteractionEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var person: Person?
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?

    
    // MARK: Init

    init(
        rid: Int? = nil,
        timeStart: Date = .now,
        timeEnd: Date? = nil,
        timed: Bool = true,
        percentage: Int = 100,
        parentInstance: ActivityInstance? = nil,
        person: Person? = nil,
        in_person: Bool = true,
        details: String? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.rid = rid
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.timed = timed
        self.percentage = percentage
        self.person = person
        self.inPerson = in_person
        self.parentInstance = parentInstance
        self.details = details
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: InteractionDTO) {
        self.init()
        
        self.rid = dto.id
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.percentage = dto.percentage ?? 100
        self.timed = dto.timed
        self.personRid = dto.person_id
        self.inPerson = dto.in_person
        self.details = dto.details
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: InteractionDTO) {
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.timed = dto.timed
        self.percentage = dto.percentage ?? 100

        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.personRid = dto.person_id
        self.timed = dto.timed
        self.inPerson = dto.in_person
        self.details = dto.details
        
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
    var timed: Bool
    var percentage: Int?
    var person_id: Int
    var in_person: Bool
    var parent_instance_id: Int?
    let parent_trip_id: Int?
    var details: String?
}


struct InteractionPayload: Codable, InitializableWithModel {
    
    typealias Model = Interaction
    
    var time_start: Date?
    var time_end: Date?
    var timed: Bool
    var percentage: Int
    var person_id: Int?
    var in_person: Bool
    var parent_instance_id: Int?
    let parent_trip_id: Int?
    var details: String?
        
    /// Creates a payload directly from a Interaction model object.
    /// This is the primary initializer you'll use in your ViewModel.
    init?(from interaction: Interaction) {
        guard interaction.isValid(),
              let personRid = interaction.personRid
        else {
            print("-> Interaction \(interaction.id) is invalid.")
            return nil
        }
        self.time_start = interaction.timeStart
        self.time_end = interaction.timeEnd
        self.parent_instance_id = interaction.parentInstanceRid
        self.parent_trip_id = interaction.parentTripRid
        self.person_id = personRid
        self.timed = interaction.timed
        self.in_person = interaction.inPerson
        self.details = interaction.details
        self.percentage = interaction.percentage
    }
}


struct InteractionEditor: EditorProtocol {
    
    var time_start: Date
    var time_end: Date?
    var timed: Bool
    var percentage: Int?
    var personRid: Int?
    var person: Person?
    var in_person: Bool
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance?
    var details: String?
    
    typealias Model = Interaction

    // MARK: - Derived flags
    
    var isPersonArchived: Bool {
        person == nil && personRid != nil
    }
    
    var hasParent: Bool {
        parentInstance != nil || parentInstanceRid != nil
    }
    
    // MARK: - Init from model
    
    init(from interaction: Interaction) {
        self.time_start = interaction.timeStart
        self.time_end = interaction.timeEnd
        self.timed = interaction.timed
        self.percentage = interaction.percentage
        self.in_person = interaction.inPerson
        self.person = interaction.person
        self.personRid = interaction.personRid
        self.parentInstance = interaction.parentInstance
        self.parentInstanceRid = interaction.parentInstanceRid
        self.details = interaction.details
    }
    
    // MARK: - Apply back to model
    
    func apply(to interaction: Interaction) {
        interaction.timeStart = self.time_start
        interaction.timeEnd = self.time_end
        interaction.timed = self.timed
        interaction.percentage = self.percentage ?? 100
        interaction.person = self.person
        interaction.personRid = self.person?.rid
        interaction.inPerson = self.in_person
        interaction.parentInstance = self.parentInstance
        interaction.parentInstanceRid = self.parentInstance?.rid
        interaction.details = self.details

        interaction.markAsModified()
    }
}
