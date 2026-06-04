//
//  Place.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation
import SwiftData

// MARK: - SwiftData Model
@Model
final class Place: CatalogueModel, EditableModel {
    
    @Attribute(.unique) var rid: Int?
    var name: String
    var cityRid: Int?

    var cache: Bool = false
    var archived: Bool = false
    var isFavorite: Bool = false
    var allowedVehicleRids: [Int] = []
    var allowedVehicleTypeSlugs: [String] = []
    var syncStatusRaw: String = SyncStatus.unsynced.rawValue
    
    typealias DTO = PlaceDTO
    typealias Payload = PlacePayload
    typealias Editor = PlaceEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var city: City?
    
    // MARK: Relationship conformance
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.placeStart)
    var startTrips: [Trip]?
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.placeEnd)
    var endTrips: [Trip]?
    
    @Relationship(deleteRule: .nullify, inverse: \Path.placeStart)
    var startPaths: [Path]?
    
    @Relationship(deleteRule: .nullify, inverse: \Path.placeEnd)
    var endPaths: [Path]?
    
    // MARK: Init


    init(rid: Int? = nil,
         name: String = "Unset",
         cityRid: Int? = nil,
         city: City? = nil,
         cache: Bool = true,
         archived: Bool = false,
         isFavorite: Bool = false,
         allowedVehicleRids: [Int] = [],
         allowedVehicleTypeSlugs: [String] = [],
         syncStatus: SyncStatus = .unsynced) {
        self.rid = rid
        self.name = name
        self.cityRid = cityRid
        self.cache = cache
        self.archived = archived
        self.isFavorite = isFavorite
        self.allowedVehicleRids = allowedVehicleRids
        self.allowedVehicleTypeSlugs = allowedVehicleTypeSlugs
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: PlaceDTO) {
        self.init(
            rid: dto.id,
            name: dto.name,
            cityRid: dto.city_id,
            archived: dto.archived,
            allowedVehicleRids: dto.allowed_vehicle_ids ?? [],
            allowedVehicleTypeSlugs: dto.allowed_vehicle_type_slugs ?? [],
            syncStatus: SyncStatus.synced
        )
    }
    
    func update(fromDto dto: PlaceDTO) {
        self.rid = dto.id
        self.name = dto.name
        self.cityRid = dto.city_id
        self.archived = dto.archived
        self.allowedVehicleRids = dto.allowed_vehicle_ids ?? []
        self.allowedVehicleTypeSlugs = dto.allowed_vehicle_type_slugs ?? []
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return name != "Unset" && name.count > 0 && cityRid != nil
    }
}


// MARK: - DTOs for Network
struct PlaceDTO: Codable, Identifiable, Sendable {
    var id: Int
    var name: String
    var city_id: Int
    var archived: Bool
    var allowed_vehicle_ids: [Int]?
    var allowed_vehicle_type_slugs: [String]?
}

struct PlacePayload: Codable, InitializableWithModel {
    
    typealias Model = Place
    var name: String
    var city_id: Int
    var archived: Bool
    var allowed_vehicle_ids: [Int]?
    var allowed_vehicle_type_slugs: [String]?
    
    init?(from place: Place) {
        guard place.isValid(), let cityRid = place.cityRid else {
            return nil
        }
        self.name = place.name
        self.city_id = cityRid
        self.archived = place.archived
        self.allowed_vehicle_ids = place.allowedVehicleRids.isEmpty ? nil : place.allowedVehicleRids
        self.allowed_vehicle_type_slugs = place.allowedVehicleTypeSlugs.isEmpty ? nil : place.allowedVehicleTypeSlugs
    }
}

struct PlaceEditor: CachableModel, EditorProtocol {
    var rid: Int?
    var slug: String?
    var name: String
    var cityRid: Int?
    var city: City?
    var cache: Bool
    var archived: Bool
    var isFavorite: Bool
    var allowedVehicleRids: [Int]
    var allowedVehicleTypeSlugs: [String]
    
    typealias Model = Place
    
    init(from place: Place) {
        self.rid = place.rid
        self.name = place.name
        self.cityRid = place.cityRid
        self.city = place.city
        self.cache = place.cache
        self.archived = place.archived
        self.isFavorite = place.isFavorite
        self.allowedVehicleRids = place.allowedVehicleRids
        self.allowedVehicleTypeSlugs = place.allowedVehicleTypeSlugs
    }
    
    func apply(to place: Place) {
        place.rid = self.rid
        place.name = self.name
        place.cityRid = self.cityRid
        place.cache = self.cache
        place.archived = self.archived
        place.isFavorite = self.isFavorite
        place.allowedVehicleRids = self.allowedVehicleRids
        place.allowedVehicleTypeSlugs = self.allowedVehicleTypeSlugs
    }
}
