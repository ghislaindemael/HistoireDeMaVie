//
//  Path.swift
//  HDMV
//
//  Created by Ghislain Demael on 26.09.2025.
//

import SwiftData

import SwiftData

@Model
final class Path: CatalogueModel {
    
    
    @Attribute(.unique) var id: Int
    var rid: Int?
    var name: String?
    var details: String?
    
    // Relationships
    var placeStart: Place?
    var placeEnd: Place?
    
    var metrics: PathMetrics = PathMetrics()
    var geojsonTrack: GeoJSONLineString?
    
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = PathPayload
    typealias DTO = PathDTO
    typealias Editor = PathEditor
    
    // MARK: - Initializers
    
    /// Regular initializer
    init(
        id: Int = Int.random(in: -999_999 ... -1),
        name: String? = nil,
        details: String? = nil,
        placeStart: Place? = nil,
        placeEnd: Place? = nil,
        metrics: PathMetrics = PathMetrics(),
        geojsonTrack: GeoJSONLineString? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .local
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.placeStart = placeStart
        self.placeEnd = placeEnd
        self.metrics = metrics
        self.geojsonTrack = geojsonTrack
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: PathDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            details: dto.details,
            metrics: dto.metrics,
            geojsonTrack: dto.geojson_track,
            cache: dto.cache,
            archived: dto.archived,
            syncStatus: .synced
        )
    }
    
    // MARK: - Update
    
    func update(fromDto dto: PathDTO) {
        self.name = dto.name
        self.details = dto.details
        self.metrics = dto.metrics
        self.geojsonTrack = dto.geojson_track
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    // MARK: - Validation
    
    func isValid() -> Bool {
        guard name != nil,
              placeStart != nil,
              placeEnd != nil
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
    var place_start_id: Int
    var place_end_id: Int
    var distance: Double?
    var metrics: PathMetrics
    var geojson_track: GeoJSONLineString?
    var path_ids: [Int]?
    var cache: Bool
    var archived: Bool
}

struct PathPayload: Codable, InitializableWithModel {
    
    typealias Model = Path
    
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
        guard path.isValid(),
              let startId = path.placeStart?.rid,
              let endId = path.placeEnd?.rid
        else { return nil }
        
        self.name = path.name!
        self.details = path.details
        self.place_start_id = startId
        self.place_end_id = endId
        self.metrics = path.metrics
        self.geojson_track = path.geojsonTrack
        self.cache = path.cache
        self.archived = path.archived
    }
}


struct PathEditor : EditorProtocol {
    
    var rid: Int?
    var name: String?
    var details: String?
    var placeStart: Place?
    var placeEnd: Place?
    var distance: Double?
    var metrics: PathMetrics = PathMetrics()
    var geojson_track: GeoJSONLineString?
    var path_ids: [Int]?
    var cache: Bool
    var archived: Bool
    
    typealias Model = Path
    
    init(from path: Path) {
        self.name = path.name
        self.details = path.details
        self.placeStart = path.placeStart
        self.placeEnd = path.placeEnd
        self.metrics = path.metrics
        self.geojson_track = path.geojsonTrack
        self.cache = path.cache
        self.archived = path.archived
    }
    
    func apply(to path: Path) {
        path.name = name
        path.details = details
        path.placeStart = placeStart
        path.placeEnd = placeEnd
        path.metrics = metrics
        path.geojsonTrack = geojson_track
        path.cache = cache
        path.archived = archived
    }
    
}
