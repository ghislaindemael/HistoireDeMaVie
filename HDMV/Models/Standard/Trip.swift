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
final class Trip: Identifiable, SyncableModel {
        
    var rid: Int?
    var time_start: Date
    var time_end: Date?
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance? {
        didSet {
            parentInstanceRid = parentInstance.rid
        }
    }
    var vehicle: Vehicle?
    var placeStart: Place?
    var placeEnd: Place?
    var path: Path?
    var am_driver: Bool
    var path_str: String?

    var details: String?
    var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = TripLegDTO
    typealias Payload = TripLegPayload

    init(rid: Int? = nil,
         time_start: Date,
         time_end: Date? = nil,
         parentInstance: ActivityInstance? = nil,
         vehicle: Vehicle? = nil,
         placeStart: Place? = nil,
         placeEnd: Place? = nil,
         am_driver: Bool = false,
         path: Path? = nil,
         details: String? = nil,
         syncStatus: SyncStatus = .local)
    {
        self.rid = rid
        self.parentInstance = parentInstance
        self.time_start = time_start
        self.time_end = time_end
        self.vehicle = vehicle
        self.placeStart = placeStart
        self.placeEnd = placeEnd
        self.am_driver = am_driver
        self.path = path
        self.details = details
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: TripLegDTO) {
        self.init(
            rid: dto.id,
            time_start: dto.timeStart,
            time_end: dto.timeEnd,
        )
    }
    
    func update(fromDto dto: TripLegDTO) {
        self.rid = dto.id
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return parentInstance != nil && placeStart != nil && placeEnd != nil && time_end != nil
    }
    
}


struct TripLegDTO: Identifiable, Codable, Sendable {
    let id: Int
    let parentId: Int?
    let timeStart: Date
    let timeEnd: Date?
    let vehicleId: Int?
    let placeStartId: Int?
    let placeEndId: Int?
    let amDriver: Bool
    let pathId: Int?
    let details: String?
    
    enum CodingKeys: String, CodingKey {
        case id, details
        case parentId = "parent_id"
        case timeStart = "time_start"
        case timeEnd = "time_end"
        case vehicleId = "vehicle_id"
        case placeStartId = "place_start_id"
        case placeEndId = "place_end_id"
        case amDriver = "am_driver"
        case pathId = "path_id"
    }
}

struct TripLegPayload: Codable, InitializableWithModel {
    typealias Model = Trip
    
    let parentId: Int
    let timeStart: Date
    let timeEnd: Date
    let vehicleId: Int?
    let placeStartId: Int
    let placeEndId: Int
    let amDriver: Bool
    let pathId: Int?
    let details: String?
    
    init?(from tripLeg: Trip) {
        guard tripLeg.isValid(),
              let parentId = tripLeg.parentInstance?.rid,
              let timeEnd = tripLeg.time_end,
              let placeStartId = tripLeg.placeStart?.rid,
              let placeEndId = tripLeg.placeEnd?.rid
        else { return nil }
        
        self.parentId = parentId
        self.timeStart = tripLeg.time_start
        self.timeEnd = timeEnd
        self.vehicleId = tripLeg.vehicle?.rid
        self.placeStartId = placeStartId
        self.placeEndId = placeEndId
        self.amDriver = tripLeg.am_driver
        self.pathId = tripLeg.path?.id
        self.details = tripLeg.details
    }
    
    enum CodingKeys: String, CodingKey {
        case details
        case parentId = "parent_id"
        case timeStart = "time_start"
        case timeEnd = "time_end"
        case vehicleId = "vehicle_id"
        case placeStartId = "place_start_id"
        case placeEndId = "place_end_id"
        case amDriver = "am_driver"
        case pathId = "path_id"
    }
}

struct TripLegEditor {
    var parent: ActivityInstance?
    var vehicle: Vehicle?
    var placeStart: Place?
    var placeEnd: Place?
    var path: Path?
    
    var time_start: Date
    var time_end: Date?
    var am_driver: Bool
    var details: String?
    
    /// Initializes the editor with data from an existing TripLeg.
    init(tripLeg: Trip) {
        self.time_start = tripLeg.time_start
        self.time_end = tripLeg.time_end
        self.am_driver = tripLeg.am_driver
        self.details = tripLeg.details
        self.parent = tripLeg.parentInstance
        self.vehicle = tripLeg.vehicle
        self.placeStart = tripLeg.placeStart
        self.placeEnd = tripLeg.placeEnd
        self.path = tripLeg.path
    }
    
    /// Applies the changes from the editor back to the original TripLeg model.
    func apply(to tripLeg: Trip) {
        tripLeg.time_start = self.time_start
        tripLeg.time_end = self.time_end
        tripLeg.am_driver = self.am_driver
        tripLeg.details = self.details
        tripLeg.parentInstance = self.parent
        tripLeg.vehicle = self.vehicle
        tripLeg.placeStart = self.placeStart
        tripLeg.placeEnd = self.placeEnd
        tripLeg.path = self.path
        
        tripLeg.markAsModified()
    }
}
