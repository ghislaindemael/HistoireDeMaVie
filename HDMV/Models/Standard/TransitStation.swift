//
//  TransitStation.swift
//  HDMV
//

import SwiftData
import Foundation

@Model
final class TransitStation: CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    var name: String = "Unset"
    var lat: Double?
    var lon: Double?
    
    var placeRid: Int?
    
    var cache: Bool = false
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = TransitStationPayload
    typealias DTO = TransitStationDTO
    typealias Editor = TransitStationEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var place: Place?
    
    @Relationship(deleteRule: .cascade, inverse: \TransitStop.station)
    var stops: [TransitStop]?
    
    // MARK: - Init
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        lat: Double? = nil,
        lon: Double? = nil,
        place: Place? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.lat = lat
        self.lon = lon
        self.place = place
        self.placeRid = place?.rid
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: TransitStationDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.lat = dto.lat
        self.lon = dto.lon
        self.placeRid = dto.place_id
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    // MARK: - Update
    
    func update(fromDto dto: TransitStationDTO) {
        self.name = dto.name
        self.lat = dto.lat
        self.lon = dto.lon
        self.placeRid = dto.place_id
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    // MARK: - Validation
    
    func isValid() -> Bool {
        return name.isNotUnset()
    }
}

struct TransitStationDTO: Codable, Sendable, Identifiable {
    var id: Int
    var name: String
    var lat: Double?
    var lon: Double?
    var place_id: Int?
    var archived: Bool?
}

struct TransitStationPayload: Codable, InitializableWithModel {
    typealias Model = TransitStation
    
    var name: String
    var lat: Double?
    var lon: Double?
    var place_id: Int?
    var archived: Bool
    
    init?(from station: TransitStation) {
        guard station.isValid() else { return nil }
        self.name = station.name
        self.lat = station.lat
        self.lon = station.lon
        self.place_id = station.placeRid
        self.archived = station.archived
    }
}

struct TransitStationEditor: EditorProtocol {
    var rid: Int?
    var name: String
    var lat: Double?
    var lon: Double?
    var placeRid: Int?
    var place: Place?
    var cache: Bool
    var archived: Bool
    
    typealias Model = TransitStation
    
    init(from station: TransitStation) {
        self.rid = station.rid
        self.name = station.name
        self.lat = station.lat
        self.lon = station.lon
        self.placeRid = station.placeRid
        self.place = station.place
        self.cache = station.cache
        self.archived = station.archived
    }
    
    func apply(to station: TransitStation) {
        station.name = name
        station.lat = lat
        station.lon = lon
        station.place = place
        station.placeRid = place?.rid ?? placeRid
        station.cache = cache
        station.archived = archived
    }
}
