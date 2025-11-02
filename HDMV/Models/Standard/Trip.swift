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
    var timeStart: Date = Date()
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
    var amDriver: Bool = false
    var pathRid: Int?
    @Relationship(deleteRule: .nullify)
    var path: Path? {
        didSet { pathRid = path?.rid }
    }
    var details: String?
    var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = TripDTO
    typealias Payload = TripPayload
    typealias Editor = TripEditor

    init(rid: Int? = nil,
         timeStart: Date = .now,
         timeEnd: Date? = nil,
         parentInstance: ActivityInstance? = nil,
         placeStart: Place? = nil,
         placeEnd: Place? = nil,
         vehicle: Vehicle? = nil,
         amDriver: Bool = false,
         path: Path? = nil,
         details: String? = nil,
         syncStatus: SyncStatus = .local)
    {
        self.rid = rid
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.parentInstance = parentInstance
        self.placeStart = placeStart
        self.placeEnd = placeEnd
        self.vehicle = vehicle
        self.amDriver = amDriver
        self.path = path
        self.details = details
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: TripDTO) {
        self.init()
        self.rid = dto.id
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.parentInstanceRid = dto.parent_instance_id
        self.placeStartRid = dto.place_start_id
        self.placeEndRid = dto.place_end_id
        self.vehicleRid = dto.vehicle_id
        self.amDriver = dto.am_driver
        self.pathRid = dto.path_id
        self.details = dto.details
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: TripDTO) {
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.parentInstanceRid = dto.parent_instance_id
        if self.parentInstanceRid == nil {
            self.parentInstance = nil
        }
        self.placeStartRid = dto.place_start_id
        self.placeEndRid = dto.place_end_id
        self.vehicleRid = dto.vehicle_id
        self.amDriver = dto.am_driver
        self.pathRid = dto.path_id
        self.details = dto.details
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return timeEnd != nil
        && parentInstanceRid != nil
        && placeStartRid != nil
        && placeEndRid != nil
        && vehicleRid != nil
    }
    
}

struct TripDTO: Identifiable, Codable, Sendable {
    let id: Int
    let parent_instance_id: Int?
    let time_start: Date
    let time_end: Date?
    let vehicle_id: Int?
    let place_start_id: Int?
    let place_end_id: Int?
    let am_driver: Bool
    let path_id: Int?
    let details: String?
}


struct TripPayload: Codable, InitializableWithModel {

    typealias Model = Trip
    
    let time_start: Date
    let time_end: Date
    let parent_instance_id: Int
    let place_start_id: Int
    let place_end_id: Int
    let vehicle_id: Int?
    let am_driver: Bool
    let pathId: Int?
    let details: String?
    
    init?(from trip: Trip) {
        guard trip.isValid(),
              let timeEnd = trip.timeEnd,
              let parentId = trip.parentInstanceRid,
              let placeStartId = trip.placeStartRid,
              let placeEndId = trip.placeEndRid,
              let vehicleId = trip.vehicleRid
        else { return nil }
        
        self.parent_instance_id = parentId
        self.time_start = trip.timeStart
        self.time_end = timeEnd
        self.vehicle_id = vehicleId
        self.place_start_id = placeStartId
        self.place_end_id = placeEndId
        self.am_driver = trip.amDriver
        self.pathId = trip.pathRid
        self.details = trip.details
    }
    
}

struct TripEditor: TimeTrackable, EditorProtocol {
    
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool = true
    var percentage: Int = 100
    
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance?
    var vehicle: Vehicle?
    var placeStart: Place?
    var placeEnd: Place?
    var path: Path?
    
    var amDriver: Bool
    var details: String?
    
    typealias Model = Trip
    
    init(from trip: Trip) {
        self.parentInstance = trip.parentInstance
        self.timeStart = trip.timeStart
        self.timeEnd = trip.timeEnd
        self.amDriver = trip.amDriver
        self.details = trip.details
        self.vehicle = trip.vehicle
        self.placeStart = trip.placeStart
        self.placeEnd = trip.placeEnd
        self.path = trip.path
    }
    
    func apply(to trip: Trip) {

        trip.timeStart = self.timeStart
        trip.timeEnd = self.timeEnd
        trip.parentInstance = self.parentInstance
        trip.parentInstanceRid = self.parentInstanceRid
        trip.placeStart = self.placeStart
        trip.placeStartRid = self.placeStart?.rid
        trip.placeEnd = self.placeEnd
        trip.placeEndRid = self.placeEnd?.rid
        trip.vehicle = self.vehicle
        trip.vehicleRid = self.vehicle?.rid
        trip.amDriver = self.amDriver
        trip.path = self.path
        trip.pathRid = self.path?.rid
        trip.details = self.details

        trip.markAsModified()
    }
}
