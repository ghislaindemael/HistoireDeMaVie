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
final class Trip: LogModel {
        
    var rid: Int?
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool = true
    var percentage: Int = 100
    
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance? {
        didSet {
            parentInstanceRid = parentInstance.rid
        }
    }
    var placeStartRid: Int?
    @Relationship(deleteRule: .nullify)
    var placeStart: Place? {
        didSet {
            placeStartRid = placeStart?.rid
        }
    }
    var placeEndRid: Int?
    @Relationship(deleteRule: .nullify)
    var placeEnd: Place? {
        didSet {
            placeEndRid = placeEnd?.rid
        }
    }
    var vehicleRid: Int?
    @Relationship(deleteRule: .nullify)
    var vehicle: Vehicle? {
        didSet { vehicleRid = vehicle?.rid }
    }
    var pathRid: Int?
    @Relationship(deleteRule: .nullify)
    var path: Path? {
        didSet { pathRid = path?.rid }
    }
    var am_driver: Bool
    var path_str: String?
    
    var details: String?
    var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = TripDTO
    typealias Payload = TripPayload
    typealias Editor = TripEditor

    init(rid: Int? = nil,
         time_start: Date,
         time_end: Date? = nil,
         timed: Bool = true,
         percentage: Int = 100,
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
        self.timeStart = time_start
        self.timeEnd = time_end
        self.vehicle = vehicle
        self.placeStart = placeStart
        self.placeEnd = placeEnd
        self.am_driver = am_driver
        self.path = path
        self.details = details
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: TripDTO) {
        self.init(
            rid: dto.id,
            time_start: dto.time_start,
            time_end: dto.time_end,
        )
    }
    
    func update(fromDto dto: TripDTO) {
        self.rid = dto.id
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return parentInstance != nil && placeStart != nil && placeEnd != nil && timeEnd != nil
    }
    
}

struct TripDTO: Identifiable, Codable, Sendable {
    let id: Int
    let parentId: Int?
    let time_start: Date
    let time_end: Date?
    let vehicleId: Int?
    let placeStartId: Int?
    let placeEndId: Int?
    let amDriver: Bool
    let pathId: Int?
    let details: String?
    
    enum CodingKeys: String, CodingKey {
        case id, details, time_start, time_end
        case parentId = "parent_id"
        case vehicleId = "vehicle_id"
        case placeStartId = "place_start_id"
        case placeEndId = "place_end_id"
        case amDriver = "am_driver"
        case pathId = "path_id"
    }
}


struct TripPayload: Codable, InitializableWithModel {

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
    
    init?(from trip: Trip) {
        guard trip.isValid(),
              let parentId = trip.parentInstance?.rid,
              let timeEnd = trip.timeEnd,
              let placeStartId = trip.placeStart?.rid,
              let placeEndId = trip.placeEnd?.rid
        else { return nil }
        
        self.parentId = parentId
        self.timeStart = trip.timeStart
        self.timeEnd = timeEnd
        self.vehicleId = trip.vehicle?.rid
        self.placeStartId = placeStartId
        self.placeEndId = placeEndId
        self.amDriver = trip.am_driver
        self.pathId = trip.path?.id
        self.details = trip.details
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

struct TripEditor: TimeTrackable, EditorProtocol {
    
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool = true
    var percentage: Int = 100
    
    var parent: ActivityInstance?
    var vehicle: Vehicle?
    var placeStart: Place?
    var placeEnd: Place?
    var path: Path?
    
    var am_driver: Bool
    var details: String?
    
    typealias Model = Trip
    
    init(from trip: Trip) {
        self.timeStart = trip.timeStart
        self.timeEnd = trip.timeEnd
        self.am_driver = trip.am_driver
        self.details = trip.details
        self.parent = trip.parentInstance
        self.vehicle = trip.vehicle
        self.placeStart = trip.placeStart
        self.placeEnd = trip.placeEnd
        self.path = trip.path
    }
    
    func apply(to trip: Trip) {
        trip.timeStart = self.timeStart
        trip.timeEnd = self.timeEnd
        trip.am_driver = self.am_driver
        trip.details = self.details
        trip.parentInstance = self.parent
        trip.vehicle = self.vehicle
        trip.placeStart = self.placeStart
        trip.placeEnd = self.placeEnd
        trip.path = self.path
        
        trip.markAsModified()
    }
}
