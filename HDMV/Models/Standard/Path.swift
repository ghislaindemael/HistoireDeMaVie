//
//  Path.swift
//  HDMV
//
//  Created by Ghislain Demael on 26.09.2025.
//

import SwiftData

@Model
final class Path: SyncableModel {
    
    typealias Payload = PathPayload
    
    @Attribute(.unique) var id: Int
    var name: String?
    var details: String?
    var place_start_id: Int?
    var place_end_id: Int?
    var metrics: PathMetrics?
    var geojsonTrack: GeoJSONLineString?
    var path_ids: [Int]?
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue

    init(id: Int = Int.random(in: -999999 ... -1),
         name: String? = nil,
         details: String? = nil,
         place_start_id: Int? = nil,
         place_end_id: Int? = nil,
         metrics: PathMetrics? = nil,
         geojsonTrack: GeoJSONLineString? = nil,
         path_ids: [Int]? = nil,
         cache: Bool = true,
         archived: Bool = false,
         syncStatus: SyncStatus
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.place_start_id = place_start_id
        self.place_end_id = place_end_id
        self.metrics = metrics
        self.geojsonTrack = geojsonTrack
        self.path_ids = path_ids
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    init(fromDto dto: PathDTO) {
        self.id = dto.id
        self.name = dto.name
        self.details = dto.details
        self.place_start_id = dto.place_start_id
        self.place_end_id = dto.place_end_id
        self.metrics = dto.metrics
        self.geojsonTrack = dto.geojson_track
        self.path_ids = dto.path_ids
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: PathDTO){
        self.name = dto.name
        self.details = dto.details
        self.place_start_id = dto.place_start_id
        self.place_end_id = dto.place_end_id
        self.metrics = dto.metrics
        self.geojsonTrack = dto.geojson_track
        self.path_ids = dto.path_ids
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        guard name != nil,
              place_start_id != nil,
              place_end_id != nil//,
              //(metrics != nil || path_ids != nil)
            else {
                return false
            }
        return true
    }
}

struct PathDTO: Codable, Sendable {
    var id: Int
    var name: String
    var details: String?
    var place_start_id: Int
    var place_end_id: Int
    var distance: Double?
    var metrics: PathMetrics?
    var geojson_track: GeoJSONLineString?
    var path_ids: [Int]?
    var cache: Bool
    var archived: Bool
}

struct PathPayload: Codable {
    var name: String
    var details: String?
    var place_start_id: Int
    var place_end_id: Int
    var distance: Double?
    var metrics: PathMetrics?
    var geojson_track: GeoJSONLineString?
    var path_ids: [Int]?
    var cache: Bool
    var archived: Bool
    
    init?(from path: Path) {
        guard path.isValid() else { return nil }
        
        self.name = path.name!
        self.details = path.details
        self.place_start_id = path.place_start_id!
        self.place_end_id = path.place_end_id!
        self.metrics = path.metrics
        self.geojson_track = path.geojsonTrack
        self.path_ids = path.path_ids
        self.cache = path.cache
        self.archived = path.archived
    }
}

struct PathEditor {
    var name: String?
    var details: String?
    var place_start_id: Int?
    var place_end_id: Int?
    var distance: Double?
    var metrics: PathMetrics?
    var geojson_track: GeoJSONLineString?
    var path_ids: [Int]?
    var cache: Bool
    var archived: Bool
    
    init(from path: Path) {
        self.name = path.name
        self.details = path.details
        self.place_start_id = path.place_start_id
        self.place_end_id = path.place_end_id
        self.metrics = path.metrics
        self.geojson_track = path.geojsonTrack
        self.path_ids = path.path_ids
        self.cache = path.cache
        self.archived = path.archived
    }
    
    func apply(to path: Path) {
        path.name = name
        path.details = details
        path.place_start_id = place_start_id
        path.place_end_id = place_end_id
        path.metrics = metrics
        path.geojsonTrack = geojson_track
        path.path_ids = path_ids
        path.cache = cache
        path.archived = archived
    }
    
}
