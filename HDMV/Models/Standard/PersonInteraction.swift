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
final class PersonInteraction: Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var time_start: Date
    var time_end: Date?
    var person_id: Int
    var in_person: Bool
    var details: String?
    var percentage: Int
    var syncStatus: SyncStatus = SyncStatus.undef
    
    init(id: Int, time_start: Date, time_end: Date? = nil,
         person_id: Int, in_person: Bool, details: String?, percentage: Int, syncStatus: SyncStatus = .local) {
        self.id = id
        self.time_start = time_start
        self.time_end = time_end
        self.person_id = person_id
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
            person_id: dto.person_id,
            in_person: dto.in_person,
            details: dto.details,
            percentage: dto.percentage,
            syncStatus: .synced
        )
    }
    
    func update(fromDto dto: PersonInteractionDTO) {
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.person_id = dto.person_id
        self.in_person = dto.in_person
        self.details = dto.details
        self.percentage = dto.percentage
    }
}

// MARK: - DTOs for Network

struct PersonInteractionDTO: Codable, Identifiable, Sendable {
    var id: Int
    var time_start: Date
    var time_end: Date?
    var person_id: Int
    var in_person: Bool
    var details: String?
    var percentage: Int
    
    enum CodingKeys: String, CodingKey {
        case id, details, percentage
        case time_start = "time_start"
        case time_end = "time_end"
        case person_id = "person_id"
        case in_person = "in_person"
    }
}


struct PersonInteractionPayload: Encodable {
    // MARK: - Properties
    var time_start: Date
    var time_end: Date?
    var person_id: Int
    var in_person: Bool
    var details: String?
    var percentage: Int
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case details, percentage
        case time_start = "time_start"
        case time_end = "time_end"
        case person_id = "person_id"
        case in_person = "in_person"
    }
    
    // MARK: - Initializer
    
    /// Creates a payload directly from a PersonInteraction model object.
    /// This is the primary initializer you'll use in your ViewModel.
    init(from interaction: PersonInteraction) {
        self.time_start = interaction.time_start
        self.time_end = interaction.time_end
        self.person_id = interaction.person_id
        self.in_person = interaction.in_person
        self.details = interaction.details
        self.percentage = interaction.percentage
    }
}
