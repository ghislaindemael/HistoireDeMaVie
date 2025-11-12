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
    
    var parentInstanceRid: Int?
    var parentTripRid: Int?
    var showChildren: Bool = true
    
    var placeStartRid: Int?
    var placeEndRid: Int?
    var vehicleRid: Int?

    var amDriver: Bool = false
    var pathRid: Int?

    var details: String?
    var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = TripDTO
    typealias Payload = TripPayload
    typealias Editor = TripEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?
    
    @Relationship(deleteRule: .nullify)
    var placeStart: Place?
    
    @Relationship(deleteRule: .nullify)
    var placeEnd: Place?
    
    @Relationship(deleteRule: .nullify)
    var vehicle: Vehicle?
    
    @Relationship(deleteRule: .nullify)
    var path: Path?
    
    @Relationship(deleteRule: .nullify, inverse: \ActivityInstance.parentTrip)
    var childActivities: [ActivityInstance]? = []
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.parentTrip)
    var childTrips: [Trip]? = nil
    
    @Relationship(deleteRule: .nullify, inverse: \Interaction.parentTrip)
    var childInteractions: [Interaction]? = nil
    
    @Relationship(deleteRule: .nullify, inverse: \LifeEvent.parentTrip)
    var childLifeEvents: [LifeEvent]? = nil
    
    
    // MARK: Relationship conformance
    
    
    
    // MARK: Init

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
        self.parentInstanceRid = parentInstance?.rid
        self.amDriver = amDriver
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
        return parentInstanceRid != nil
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

struct TripEditor: TimeBound, EditorProtocol {
    
    var timeStart: Date
    var timeEnd: Date?
    
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance?
    
    var vehicleRid: Int?
    var vehicle: Vehicle?
    
    var placeStartRid: Int?
    var placeStart: Place?
    
    var placeEndRid: Int?
    var placeEnd: Place?
    
    var pathRid: Int?
    var path: Path?
    
    var amDriver: Bool
    var details: String?
    
    typealias Model = Trip
    
    init(from trip: Trip) {
        self.timeStart = trip.timeStart
        self.timeEnd = trip.timeEnd
        
        self.parentInstanceRid = trip.parentInstanceRid
        self.parentInstance = trip.parentInstance
        
        self.vehicleRid = trip.vehicleRid
        self.vehicle = trip.vehicle
        
        self.placeStartRid = trip.placeStartRid
        self.placeStart = trip.placeStart
        
        self.placeEndRid = trip.placeEndRid
        self.placeEnd = trip.placeEnd
        
        self.pathRid = trip.pathRid
        self.path = trip.path
        
        self.amDriver = trip.amDriver
        self.details = trip.details
    }
    
    func apply(to trip: Trip) {
        trip.timeStart = timeStart
        trip.timeEnd = timeEnd
        trip.amDriver = amDriver
        trip.details = details
        
        trip.setParentInstance(parentInstance, fallbackRid: parentInstanceRid)
        trip.setPlaceStart(placeStart, fallbackRid: placeStartRid)
        trip.setPlaceEnd(placeEnd, fallbackRid: placeEndRid)
        trip.setVehicle(vehicle, fallbackRid: vehicleRid)
        trip.setPath(path, fallbackRid: pathRid)
        
        trip.markAsModified()
    }
}
