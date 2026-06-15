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
    @Attribute var childrenDisplayModeRaw: String = ChildrenDisplayMode.all.rawValue
    
    var contextRids: [Int] = []
    
    var placeStartRid: Int?
    var placeEndRid: Int?
    var vehicleRid: Int?
    
    var amDriver: Bool = false
    
    var pathRid: Int?
    var pathMetricsData: Data?
    var geojsonTrackData: Data?
    
    var transitLineRid: Int?
    
    var fitFilePath: String?
    
    var persons: [Person] = []
    var personRids: [Int] = []
    
    var details: String?
    var activity_details: Data?
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
    
    @Relationship(deleteRule: .nullify)
    var transitLine: TransitLine?
    
    @Relationship(deleteRule: .nullify, inverse: \ActivityInstance.parentTrip)
    var childActivities: [ActivityInstance] = []
    
    // For protocol conformance, a Trip cannot hold another trip
    @Relationship(deleteRule: .nullify, inverse: \Trip.parentTrip)
    var childTrips: [Trip] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Interaction.parentTrip)
    var childInteractions: [Interaction] = []
    
    @Relationship(deleteRule: .nullify, inverse: \LifeEvent.parentTrip)
    var childLifeEvents: [LifeEvent] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Quote.parentTrip)
    var childQuotes: [Quote] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.parentTrip)
    var childTransactions: [Transaction] = []
    
    
    // MARK: Derived properties
    
    var pathMetrics: PathMetrics? {
        get {
            guard let data = pathMetricsData else { return nil }
            return try? JSONDecoder().decode(PathMetrics.self, from: data)
        }
        set {
            pathMetricsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var geojsonTrack: GeoJSONLineString? {
        get {
            guard let data = geojsonTrackData else { return nil }
            return try? JSONDecoder().decode(GeoJSONLineString.self, from: data)
        }
        set {
            geojsonTrackData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var decodedActivityDetails: ActivityDetails? {
        get {
            guard let data = activity_details else { return nil }
            return try? JSONDecoder().decode(ActivityDetails.self, from: data)
        }
        set {
            activity_details = try? JSONEncoder().encode(newValue)
        }
    }
    
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
         transitLine: TransitLine? = nil,
         fitFilePath: String? = nil,
         contextRids: [Int] = [],
         details: String? = nil,
         activity_details: ActivityDetails? = nil,
         syncStatus: SyncStatus = .unsynced)
    {
        self.rid = rid
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.parentInstance = parentInstance
        self.parentInstanceRid = parentInstance?.rid
        self.amDriver = amDriver
        self.transitLineRid = transitLine?.rid
        self.fitFilePath = fitFilePath
        self.contextRids = contextRids
        self.details = details
        self.decodedActivityDetails = activity_details
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
        self.transitLineRid = dto.transit_line_id
        self.personRids = dto.person_ids ?? []
        self.fitFilePath = dto.fit_file_path
        self.contextRids = dto.context_ids ?? []
        self.details = dto.details
        self.decodedActivityDetails = dto.activity_details
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
        self.transitLineRid = dto.transit_line_id
        self.fitFilePath = dto.fit_file_path
        
        self.personRids = dto.person_ids ?? []
        
        let currentRids = Set(self.persons.compactMap { $0.rid })
        let newRids = Set(dto.person_ids ?? [])
        if currentRids != newRids {
            self.persons = []
        }
        
        self.contextRids = dto.context_ids ?? []
        self.details = dto.details
        self.decodedActivityDetails = dto.activity_details
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
    let transit_line_id: Int?
    let path_metrics: PathMetrics?
    let geojson_track: GeoJSONLineString?
    let fit_file_path: String?
    let person_ids: [Int]?
    let context_ids: [Int]?
    let details: String?
    let activity_details: ActivityDetails?
}


struct TripPayload: Codable, InitializableWithModel {
    
    typealias Model = Trip
    
    let time_start: Date
    let time_end: Date?
    let parent_instance_id: Int
    let place_start_id: Int
    let place_end_id: Int
    let vehicle_id: Int?
    let am_driver: Bool
    let path_id: Int?
    let transit_line_id: Int?
    let path_metrics: PathMetrics?
    let geojson_track: GeoJSONLineString?
    let fit_file_path: String?
    let person_ids: [Int]
    let context_ids: [Int]
    let details: String?
    let activity_details: ActivityDetails?
    
    init?(from trip: Trip) {
        guard trip.isValid(),
              let parentId = trip.parentInstanceRid,
              let placeStartId = trip.placeStartRid,
              let placeEndId = trip.placeEndRid,
              let vehicleId = trip.vehicleRid
        else { return nil }
        
        self.parent_instance_id = parentId
        self.time_start = trip.timeStart
        self.time_end = trip.timeEnd
        self.vehicle_id = vehicleId
        self.place_start_id = placeStartId
        self.place_end_id = placeEndId
        self.am_driver = trip.amDriver
        self.path_id = trip.pathRid
        self.transit_line_id = trip.transitLineRid
        self.path_metrics = trip.pathMetrics
        self.geojson_track = trip.geojsonTrack
        self.fit_file_path = trip.fitFilePath
        self.details = trip.details
        self.person_ids = trip.personRids
        self.context_ids = trip.contextRids
        
        if var activityDetails = trip.decodedActivityDetails {
            activityDetails.removeFields()
            self.activity_details = activityDetails
        } else {
            self.activity_details = nil
        }
    }
    
}

struct TripEditor: TimeBound, EditorProtocol, LinkedParent {
    
    var timeStart: Date
    var timeEnd: Date?
    
    var parentInstanceRid: Int?
    var parentInstance: ActivityInstance?
    
    var parentTripRid: Int?
    var parentTrip: Trip?
    
    var vehicleRid: Int?
    var vehicle: Vehicle?
    
    var placeStartRid: Int?
    var placeStart: Place?
    
    var placeEndRid: Int?
    var placeEnd: Place?
    
    var pathRid: Int?
    var path: Path?
    var transitLineRid: Int?
    var transitLine: TransitLine?
    var pathMetrics: PathMetrics?
    var geojsonTrack: GeoJSONLineString?
    
    var fitFilePath: String?
    
    var amDriver: Bool
    var details: String?
    var decodedActivityDetails: ActivityDetails?
    
    var persons: [Person] = []
    var personRids: [Int] = []
    var contextRids: [Int] = []
    
    typealias Model = Trip
    
    init(from trip: Trip) {
        self.timeStart = trip.timeStart
        self.timeEnd = trip.timeEnd
        
        self.parentInstanceRid = trip.parentInstanceRid
        self.parentInstance = trip.parentInstance
        
        self.parentTripRid = trip.parentTripRid
        self.parentTrip = trip.parentTrip
        
        self.vehicleRid = trip.vehicleRid
        self.vehicle = trip.vehicle
        
        self.placeStartRid = trip.placeStartRid
        self.placeStart = trip.placeStart
        
        self.placeEndRid = trip.placeEndRid
        self.placeEnd = trip.placeEnd
        
        self.pathRid = trip.pathRid
        self.path = trip.path
        self.transitLineRid = trip.transitLineRid
        self.transitLine = trip.transitLine
        self.pathMetrics = trip.pathMetrics
        self.geojsonTrack = trip.geojsonTrack
        
        self.fitFilePath = trip.fitFilePath
        
        self.amDriver = trip.amDriver
        self.details = trip.details
        self.decodedActivityDetails = trip.decodedActivityDetails
        
        self.persons = trip.persons
        self.personRids = trip.personRids
        self.contextRids = trip.contextRids
    }
    
    func apply(to trip: Trip) {
        trip.timeStart = timeStart
        trip.timeEnd = timeEnd
        trip.amDriver = amDriver
        trip.details = details
        trip.decodedActivityDetails = decodedActivityDetails
        trip.fitFilePath = fitFilePath
        
        trip.parentInstance = parentInstance
        trip.parentInstanceRid = parentInstance?.rid ?? parentInstanceRid
        trip.parentTrip = parentTrip
        trip.parentTripRid = parentTrip?.rid ?? parentTripRid
        trip.setPlaceStart(placeStart, fallbackRid: placeStartRid)
        trip.setPlaceEnd(placeEnd, fallbackRid: placeEndRid)
        trip.setVehicle(vehicle, fallbackRid: vehicleRid)
        trip.setPath(path, fallbackRid: pathRid)
        trip.setTransitLine(transitLine, fallbackRid: transitLineRid)
        
        trip.pathMetrics = pathMetrics
        trip.geojsonTrack = geojsonTrack
        
        trip.persons = self.persons
        trip.personRids = self.persons.compactMap { $0.rid }
        trip.contextRids = self.contextRids
        
        trip.markAsModified()
    }
}

extension Trip {
    @discardableResult
    static func create(in context: ModelContext, parent: any ParentModel, filterDate: Date) -> Trip {
        let calendar = Calendar.current
        let tripStart: Date
        let tripEnd: Date?
        
        if calendar.isDateInToday(filterDate) {
            tripStart = Date()
            tripEnd = nil
        } else {
            tripStart = parent.timeStart.addingTimeInterval(1)
            let parentDuration: TimeInterval
            if let end = parent.timeEnd {
                parentDuration = end.timeIntervalSince(parent.timeStart)
            } else {
                parentDuration = .infinity
            }
            
            if parentDuration < 15 * 60 {
                let parentActualEnd = parent.timeEnd ?? parent.timeStart.addingTimeInterval(parentDuration)
                tripEnd = parentActualEnd.addingTimeInterval(-1)
            } else {
                tripEnd = tripStart.addingTimeInterval(15 * 60)
            }
        }
        
        var newTrip = Trip(timeStart: tripStart, timeEnd: tripEnd)
        newTrip.setParent(parent)
        context.insert(newTrip)
        try? context.save()
        return newTrip
    }
}
