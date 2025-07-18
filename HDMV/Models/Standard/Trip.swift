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
final class Trip {
    @Attribute(.unique) var id: Int
    
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var path_str: String?
    var details: String?
    
    var syncStatusRawValue: String = SyncStatus.local.rawValue
    
    var syncStatus: SyncStatus {
        get {
            SyncStatus(rawValue: syncStatusRawValue) ?? .undef
        }
        set {
            syncStatusRawValue = newValue.rawValue
        }
    }
    
    init(id: Int = Int.random(in: 1...999999),
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
}

struct TripDTO: Codable, Sendable {
    var id: Int?
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var path_str: String?
    var details: String?
}

struct TripPayload: Codable {
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var path_str: String?
    var details: String?
}

struct TripDisplayModel: Identifiable, Hashable {
    let id: Int
    let time_start: Date
    let time_end: Date?
    let vehicle_id: Int?
    let place_start_id: Int?
    let place_end_id: Int?
    let am_driver: Bool
    let path_str: String?
    let details: String?
    
    /// True if this trip represents a local, unsynced change.
    let isLocal: Bool
    
    // Initializer for a trip from the network (DTO)
    init(dto: TripDTO) {
        self.id = dto.id ?? 0
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.vehicle_id = dto.vehicle_id
        self.place_start_id = dto.place_start_id
        self.place_end_id = dto.place_end_id
        self.am_driver = dto.am_driver
        self.path_str = dto.path_str
        self.details = dto.details
        self.isLocal = false // Data from the network is never "local"
    }
    
    // Initializer for a trip from the local cache (@Model)
    init(model: Trip) {
        self.id = model.id
        self.time_start = model.time_start
        self.time_end = model.time_end
        self.vehicle_id = model.vehicle_id
        self.place_start_id = model.place_start_id
        self.place_end_id = model.place_end_id
        self.am_driver = model.am_driver
        self.path_str = model.path_str
        self.details = model.details
        self.isLocal = model.syncStatus != .synced // Use syncStatus to determine the flag
    }
}
