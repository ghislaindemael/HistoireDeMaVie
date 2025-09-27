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
final class TripLeg: Identifiable, SyncableModel {
    @Attribute(.unique) var id: Int
    
    var parent_id: Int?
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var path_str: String?
    var path_ids: [Int] = []
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
        self.path_ids = dto.path_ids
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
        self.path_ids = dto.path_ids
        self.details = dto.details
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        guard parent_id != nil,
              place_start_id != nil,
              place_end_id != nil,
              vehicle_id != nil,
              //time_start != nil,
              time_end != nil else {
            return false
        }
        return true
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
    var path_ids: [Int]
    var details: String?
}

struct TripLegPayload: Codable {
    var parent_id: Int
    var time_start: Date
    var time_end: Date
    var vehicle_id: Int
    var place_start_id: Int
    var place_end_id: Int
    var am_driver: Bool
    var path_str: String?
    var path_ids: [Int]
    var details: String?
    
    init?(from tripLeg: TripLeg) {
        guard tripLeg.isValid() else { return nil }
        
        self.parent_id = tripLeg.parent_id!
        self.time_start = tripLeg.time_start
        self.time_end = tripLeg.time_end!
        self.vehicle_id = tripLeg.vehicle_id!
        self.place_start_id = tripLeg.place_start_id!
        self.place_end_id = tripLeg.place_end_id!
        self.am_driver = tripLeg.am_driver
        self.path_str = tripLeg.path_str
        self.path_ids = tripLeg.path_ids
        self.details = tripLeg.details
    }
}

struct TripLegEditor {
    var parent_id: Int?
    var time_start: Date
    var time_end: Date?
    var vehicle_id: Int?
    var place_start_id: Int?
    var place_end_id: Int?
    var am_driver: Bool
    var details: String?
    var path_ids: [Int]
        
    /// Initializes the editor with data from an existing TripLeg.
    init(tripLeg: TripLeg) {
        self.time_start = tripLeg.time_start
        self.time_end = tripLeg.time_end
        self.vehicle_id = tripLeg.vehicle_id
        self.place_start_id = tripLeg.place_start_id
        self.place_end_id = tripLeg.place_end_id
        self.am_driver = tripLeg.am_driver
        self.details = tripLeg.details
        self.parent_id = tripLeg.parent_id
        self.path_ids = tripLeg.path_ids
    }
    
    /// Applies the changes from the editor back to the original TripLeg model.
    func apply(to tripLeg: TripLeg) {
        tripLeg.time_start = self.time_start
        tripLeg.time_end = self.time_end
        tripLeg.vehicle_id = self.vehicle_id
        tripLeg.place_start_id = self.place_start_id
        tripLeg.place_end_id = self.place_end_id
        tripLeg.am_driver = self.am_driver
        tripLeg.details = self.details
        tripLeg.path_ids = self.path_ids
        tripLeg.syncStatus = .local
    }

}
