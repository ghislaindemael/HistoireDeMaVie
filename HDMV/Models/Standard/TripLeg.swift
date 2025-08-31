//
//  Trip.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.06.2025.
//


import Foundation
import SwiftData

// MARK: - SwiftData Model
@Model
final class TripLeg : CustomStringConvertible, TimableModel, SyncableModel {
    @Attribute(.unique) var id: Int
    
    var parent_id: Int?
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var path_str: String?
    var details: String?
    var syncStatus: SyncStatus = SyncStatus.undef
    
    init(id: Int = Int.random(in: 1...999999),
         parent_id: Int? = nil,
         time_start: Date,
         time_end: Date? = nil,
         vehicle_id: Int? = nil,
         place_start_id: Int? = nil,
         place_end_id: Int? = nil,
         am_driver: Bool = false,
         path_str: String? = nil,
         details: String? = nil,
         syncStatus: SyncStatus = .local) {
        self.id = id
        self.parent_id = parent_id
        self.time_start = time_start
        self.time_end = time_end
        self.vehicle_id = vehicle_id
        self.place_start_id = place_start_id
        self.place_end_id = place_end_id
        self.am_driver = am_driver
        self.path_str = path_str
        self.details = details
        self.syncStatus = syncStatus
    }
    
    init(fromDto dto: TripLegDTO){
        self.id = dto.id
        self.parent_id = dto.parent_id
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.vehicle_id = dto.vehicle_id
        self.place_start_id = dto.place_start_id
        self.place_end_id = dto.place_end_id
        self.am_driver = dto.am_driver
        self.path_str = dto.path_str
        self.details = dto.details
        self.syncStatus = SyncStatus.synced
    }
    
    func update(fromDto dto: TripLegDTO) {
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.vehicle_id = dto.vehicle_id
        self.place_start_id = dto.place_start_id
        self.place_end_id = dto.place_end_id
        self.am_driver = dto.am_driver
        self.path_str = dto.path_str
        self.details = dto.details
        self.syncStatus = .synced
    }
    
    var description: String {
        """
        TripLeg(
            id: \(id),
            parent_id: \(parent_id ?? -1),
            time_start: \(time_start),
            time_end: \(String(describing: time_end)),
            vehicle_id: \(String(describing: vehicle_id)),
            place_start_id: \(String(describing: place_start_id)),
            place_end_id: \(String(describing: place_end_id)),
            am_driver: \(am_driver),
            path_str: \(String(describing: path_str)),
            details: \(String(describing: details)),
            syncStatus: \(syncStatus)
        )
        """
    }
}


struct TripLegDTO: Codable, Sendable {
    var id: Int
    var parent_id: Int?
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var path_str: String?
    var details: String?
}

struct TripLegPayload: Codable {
    var parent_id: Int?
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var path_str: String?
    var details: String?
}
