//
//  Path.swift
//  HDMV
//
//  Created by Ghislain Demael on 26.09.2025.
//

import SwiftData
import Foundation

enum PathMatchDirection {
    case forward
    case reverse
}

@Model
final class Path: CatalogueModel {
        
    @Attribute(.unique) var rid: Int?
    @Attribute(.unique) var name: String = "Unset"
    var details: String?
    
    var placeStartRids: [Int] = []
    var placeEndRids: [Int] = []
    var isBidirectional: Bool = true
    
    var allowedVehicleRids: [Int] = []
    var allowedVehicleTypeSlugs: [String] = []
    
    var metrics: PathMetrics = PathMetrics()
    var geojsonTrack: GeoJSONLineString?
    var gpxFilePath: String?
    
    var cache: Bool = false
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = PathPayload
    typealias DTO = PathDTO
    typealias Editor = PathEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.path)
    var trips: [Trip]?
    
    // MARK: - Computed Helpers
    
    var isLoop: Bool {
        !Set(placeStartRids).isDisjoint(with: Set(placeEndRids))
    }
    
    func matchDirection(startRid: Int, endRid: Int) -> PathMatchDirection? {
        if placeStartRids.contains(startRid) && placeEndRids.contains(endRid) {
            return .forward
        }
        if isBidirectional && placeStartRids.contains(endRid) && placeEndRids.contains(startRid) {
            return .reverse
        }
        return nil
    }
    
    func matchesAnyPlace(startRid: Int?, endRid: Int?) -> Bool {
        if let startRid, placeStartRids.contains(startRid) || (isBidirectional && placeEndRids.contains(startRid)) {
            return true
        }
        if let endRid, placeEndRids.contains(endRid) || (isBidirectional && placeStartRids.contains(endRid)) {
            return true
        }
        return false
    }
    
    func matchesVehicle(_ vehicle: Vehicle?) -> Bool {
        if allowedVehicleRids.isEmpty && allowedVehicleTypeSlugs.isEmpty {
            return true
        }
        guard let vehicle else { return true }
        if let vRid = vehicle.rid, allowedVehicleRids.contains(vRid) {
            return true
        }
        if allowedVehicleTypeSlugs.contains(vehicle.typeSlug) {
            return true
        }
        return false
    }
    
    // MARK: - Init
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        details: String? = nil,
        placeStartRids: [Int] = [],
        placeEndRids: [Int] = [],
        isBidirectional: Bool = true,
        allowedVehicleRids: [Int] = [],
        allowedVehicleTypeSlugs: [String] = [],
        metrics: PathMetrics = PathMetrics(),
        geojsonTrack: GeoJSONLineString? = nil,
        gpxFilePath: String? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.details = details
        self.placeStartRids = placeStartRids
        self.placeEndRids = placeEndRids
        self.isBidirectional = isBidirectional
        self.allowedVehicleRids = allowedVehicleRids
        self.allowedVehicleTypeSlugs = allowedVehicleTypeSlugs
        self.metrics = metrics
        self.geojsonTrack = geojsonTrack
        self.gpxFilePath = gpxFilePath
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: PathDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.details = dto.details
        self.placeStartRids = dto.place_start_ids
        self.placeEndRids = dto.place_end_ids
        self.isBidirectional = dto.is_bidirectional
        self.allowedVehicleRids = dto.allowed_vehicle_ids ?? []
        self.allowedVehicleTypeSlugs = dto.allowed_vehicle_type_slugs ?? []
        self.metrics = dto.metrics ?? PathMetrics()
        self.geojsonTrack = dto.geojson_track
        self.gpxFilePath = dto.gpx_file_path
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    // MARK: - Update
    
    func update(fromDto dto: PathDTO) {
        self.name = dto.name
        self.details = dto.details
        self.placeStartRids = dto.place_start_ids
        self.placeEndRids = dto.place_end_ids
        self.isBidirectional = dto.is_bidirectional
        self.allowedVehicleRids = dto.allowed_vehicle_ids ?? []
        self.allowedVehicleTypeSlugs = dto.allowed_vehicle_type_slugs ?? []
        self.metrics = dto.metrics ?? PathMetrics()
        self.geojsonTrack = dto.geojson_track
        self.gpxFilePath = dto.gpx_file_path
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    // MARK: - Validation
    
    func isValid() -> Bool {
        guard name.isNotUnset(),
              !placeStartRids.isEmpty,
              !placeEndRids.isEmpty
        else {
            return false
        }
        return true
    }
}

struct PathDTO: Codable, Sendable, Identifiable {
    var id: Int
    var name: String
    var details: String?
    var place_start_ids: [Int]
    var place_end_ids: [Int]
    var is_bidirectional: Bool
    var allowed_vehicle_ids: [Int]?
    var allowed_vehicle_type_slugs: [String]?
    var metrics: PathMetrics?
    var geojson_track: GeoJSONLineString?
    var gpx_file_path: String?
    var archived: Bool
}

struct PathPayload: Codable, InitializableWithModel {
    
    typealias Model = Path
    
    var name: String
    var details: String?
    var place_start_ids: [Int]
    var place_end_ids: [Int]
    var is_bidirectional: Bool
    var allowed_vehicle_ids: [Int]
    var allowed_vehicle_type_slugs: [String]
    var metrics: PathMetrics
    var geojson_track: GeoJSONLineString?
    var gpx_file_path: String?
    var archived: Bool
    
    init?(from path: Path) {
        guard path.isValid() else { return nil }
        
        self.name = path.name
        self.details = path.details
        self.place_start_ids = path.placeStartRids
        self.place_end_ids = path.placeEndRids
        self.is_bidirectional = path.isBidirectional
        self.allowed_vehicle_ids = path.allowedVehicleRids
        self.allowed_vehicle_type_slugs = path.allowedVehicleTypeSlugs
        self.metrics = path.metrics
        self.geojson_track = path.geojsonTrack
        self.gpx_file_path = path.gpxFilePath
        self.archived = path.archived
    }
}

struct PathEditor: EditorProtocol {
    
    var rid: Int?
    var name: String
    var details: String?
    var placeStartRids: [Int]
    var placeEndRids: [Int]
    var isBidirectional: Bool
    var allowedVehicleRids: [Int]
    var allowedVehicleTypeSlugs: [String]
    var metrics: PathMetrics = PathMetrics()
    var geojson_track: GeoJSONLineString?
    var gpxFilePath: String?
    var cache: Bool
    var archived: Bool
    
    typealias Model = Path
    
    init(from path: Path) {
        self.rid = path.rid
        self.name = path.name
        self.details = path.details
        self.placeStartRids = path.placeStartRids
        self.placeEndRids = path.placeEndRids
        self.isBidirectional = path.isBidirectional
        self.allowedVehicleRids = path.allowedVehicleRids
        self.allowedVehicleTypeSlugs = path.allowedVehicleTypeSlugs
        self.metrics = path.metrics
        self.geojson_track = path.geojsonTrack
        self.gpxFilePath = path.gpxFilePath
        self.cache = path.cache
        self.archived = path.archived
    }
    
    func apply(to path: Path) {
        path.name = name
        path.details = details
        path.placeStartRids = placeStartRids
        path.placeEndRids = placeEndRids
        path.isBidirectional = isBidirectional
        path.allowedVehicleRids = allowedVehicleRids
        path.allowedVehicleTypeSlugs = allowedVehicleTypeSlugs
        path.metrics = metrics
        path.geojsonTrack = geojson_track
        path.gpxFilePath = gpxFilePath
        path.cache = cache
        path.archived = archived
    }
}
