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
    
    var personRids: [Int] = []
    
    var parentInstanceRid: Int?
    var parentTripRid: Int?
    
    var details: String?
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = InteractionDTO
    typealias Payload = InteractionPayload
    typealias Editor = InteractionEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var persons: [Person] = []
    
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
        persons: [Person] = [],
        in_person: Bool = true,
        details: String? = nil,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.timed = timed
        self.percentage = percentage
        self.persons = persons
        self.personRids = persons.compactMap { $0.rid } // Auto-fill RIDs
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
        self.personRids = dto.person_ids
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
        self.personRids = dto.person_ids
        self.inPerson = dto.in_person
        self.details = dto.details
        
        let currentRids = Set(self.persons.compactMap { $0.rid })
        let newRids = Set(dto.person_ids)
        if currentRids != newRids {
            self.persons = []
        }
        
        if self.parentInstance?.rid != self.parentInstanceRid { self.parentInstance = nil }
    }
    
    // MARK: - Computed properties
    
    var isStandalone: Bool {
        parentInstance == nil
    }
    
    /// Checks if the interaction is valid for syncing.
    func isValid() -> Bool {
        guard !self.personRids.isEmpty else { return false }
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
    var person_ids: [Int]
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
    var person_ids: [Int]
    var in_person: Bool
    var parent_instance_id: Int?
    let parent_trip_id: Int?
    var details: String?
    
    init?(from interaction: Interaction) {
        guard interaction.isValid() else {
            print("-> Interaction \(interaction.id) is invalid.")
            return nil
        }
        self.time_start = interaction.timeStart
        self.time_end = interaction.timeEnd
        self.parent_instance_id = interaction.parentInstanceRid
        self.parent_trip_id = interaction.parentTripRid
        self.person_ids = interaction.personRids
        self.timed = interaction.timed
        self.in_person = interaction.inPerson
        self.details = interaction.details
        self.percentage = interaction.percentage
    }
}

// MARK: - Editor

struct InteractionEditor: EditorProtocol {
    
    var time_start: Date
    var time_end: Date?
    var timed: Bool
    var percentage: Int?
    var personRids: [Int] = []
    var persons: [Person] = []
    var in_person: Bool
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance?
    var details: String?
    
    typealias Model = Interaction
    
    // MARK: - Derived flags
    
    var isPersonArchived: Bool {
        persons.isEmpty && !personRids.isEmpty
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
        self.persons = interaction.persons
        self.personRids = interaction.personRids
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
        interaction.persons = self.persons
        interaction.personRids = self.persons.compactMap { $0.rid }
        interaction.inPerson = self.in_person
        interaction.parentInstance = self.parentInstance
        interaction.parentInstanceRid = self.parentInstance?.rid
        interaction.details = self.details
        
        interaction.markAsModified()
    }
}
