//
//  Path.swift
//  HDMV
//
//  Created by Ghislain Demael on 26.09.2025.
//

import SwiftData

@Model
final class Path: CatalogueModel {
        
    @Attribute(.unique) var rid: Int?
    @Attribute(.unique) var name: String?
    var details: String?
    
    var placeStartRid: Int?
    var placeEndRid: Int?
    
    var metrics: PathMetrics = PathMetrics()
    var geojsonTrack: GeoJSONLineString?
    
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = PathPayload
    typealias DTO = PathDTO
    typealias Editor = PathEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var placeStart: Place?
    
    @Relationship(deleteRule: .nullify)
    var placeEnd: Place?
    
    // MARK: Relationship conformance
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.path)
    var trips: [Trip]?
    
    // MARK: - Init
    
    /// Regular initializer
    init(
        rid: Int? = nil,
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
        self.rid = rid
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
        self.init()
        self.placeStartRid = dto.place_start_id
        self.placeEndRid = dto.place_end_id
        self.name = dto.name
        self.details = dto.details
        self.metrics = dto.metrics
        self.geojsonTrack = dto.geojson_track
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    // MARK: - Update
    
    func update(fromDto dto: PathDTO) {
        self.placeStartRid = dto.place_start_id
        self.placeEndRid = dto.place_end_id
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
              placeStartRid != nil,
              placeEndRid != nil
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
              let startId = path.placeStartRid,
              let endId = path.placeEndRid
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
