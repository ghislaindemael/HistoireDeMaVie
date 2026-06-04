//
//  TransitStop.swift
//  HDMV
//

import SwiftData
import Foundation

@Model
final class TransitStop: CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    var stopSequence: Int = 0
    var distanceToNext: Double?
    var geojsonToNext: GeoJSONLineString?
    
    var lineRid: Int?
    var stationRid: Int?
    
    var cache: Bool = false
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = TransitStopPayload
    typealias DTO = TransitStopDTO
    typealias Editor = TransitStopEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var line: TransitLine?
    
    @Relationship(deleteRule: .nullify)
    var station: TransitStation?
    
    // MARK: - Init
    
    init(
        rid: Int? = nil,
        stopSequence: Int = 0,
        distanceToNext: Double? = nil,
        geojsonToNext: GeoJSONLineString? = nil,
        line: TransitLine? = nil,
        station: TransitStation? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.stopSequence = stopSequence
        self.distanceToNext = distanceToNext
        self.geojsonToNext = geojsonToNext
        self.line = line
        self.lineRid = line?.rid
        self.station = station
        self.stationRid = station?.rid
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: TransitStopDTO) {
        self.init()
        self.rid = dto.id
        self.stopSequence = dto.stop_sequence
        self.distanceToNext = dto.distance_to_next
        self.geojsonToNext = dto.geojson_to_next
        self.lineRid = dto.line_id
        self.stationRid = dto.station_id
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    // MARK: - Update
    
    func update(fromDto dto: TransitStopDTO) {
        self.stopSequence = dto.stop_sequence
        self.distanceToNext = dto.distance_to_next
        self.geojsonToNext = dto.geojson_to_next
        self.lineRid = dto.line_id
        self.stationRid = dto.station_id
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    // MARK: - Validation
    
    func isValid() -> Bool {
        return lineRid != nil && stationRid != nil
    }
}

struct TransitStopDTO: Codable, Sendable, Identifiable {
    var id: Int
    var line_id: Int
    var station_id: Int
    var stop_sequence: Int
    var distance_to_next: Double?
    var geojson_to_next: GeoJSONLineString?
    var archived: Bool?
}

struct TransitStopPayload: Codable, InitializableWithModel {
    typealias Model = TransitStop
    
    var line_id: Int
    var station_id: Int
    var stop_sequence: Int
    var distance_to_next: Double?
    var geojson_to_next: GeoJSONLineString?
    var archived: Bool
    
    init?(from stop: TransitStop) {
        guard stop.isValid(), let lineId = stop.lineRid, let stationId = stop.stationRid else { return nil }
        self.line_id = lineId
        self.station_id = stationId
        self.stop_sequence = stop.stopSequence
        self.distance_to_next = stop.distanceToNext
        self.geojson_to_next = stop.geojsonToNext
        self.archived = stop.archived
    }
}

struct TransitStopEditor: EditorProtocol {
    var rid: Int?
    var stopSequence: Int
    var distanceToNext: Double?
    var geojsonToNext: GeoJSONLineString?
    var lineRid: Int?
    var line: TransitLine?
    var stationRid: Int?
    var station: TransitStation?
    var cache: Bool
    var archived: Bool
    
    typealias Model = TransitStop
    
    init(from stop: TransitStop) {
        self.rid = stop.rid
        self.stopSequence = stop.stopSequence
        self.distanceToNext = stop.distanceToNext
        self.geojsonToNext = stop.geojsonToNext
        self.lineRid = stop.lineRid
        self.line = stop.line
        self.stationRid = stop.stationRid
        self.station = stop.station
        self.cache = stop.cache
        self.archived = stop.archived
    }
    
    func apply(to stop: TransitStop) {
        stop.stopSequence = stopSequence
        stop.distanceToNext = distanceToNext
        stop.geojsonToNext = geojsonToNext
        stop.line = line
        stop.lineRid = line?.rid ?? lineRid
        stop.station = station
        stop.stationRid = station?.rid ?? stationRid
        stop.cache = cache
        stop.archived = archived
    }
}
