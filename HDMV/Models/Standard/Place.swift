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
    
    // MARK: - Dedicated Storage Fields
    var address: String?
    var isVirtual: Bool = false
    var placeTypeRid: Int?

    var cache: Bool = false
    var archived: Bool = false
    var isFavorite: Bool = false
    var allowedVehicleRids: [Int] = []
    var allowedVehicleTypeSlugs: [String] = []
    var options_details: Data?
    var syncStatusRaw: String = SyncStatus.unsynced.rawValue
    
    typealias DTO = PlaceDTO
    typealias Payload = PlacePayload
    typealias Editor = PlaceEditor
    
    // MARK: - Options & Geometry Decoding
    
    var decodedOptions: PlaceOptions? {
        get {
            guard let data = options_details else { return nil }
            return try? JSONDecoder().decode(PlaceOptions.self, from: data)
        }
        set {
            if let newValue = newValue {
                options_details = try? JSONEncoder().encode(newValue)
            } else {
                options_details = nil
            }
        }
    }
    
    var geometry: PlaceGeometry? {
        get {
            decodedOptions?.geometry
        }
        set {
            var opts = decodedOptions ?? PlaceOptions()
            opts.geometry = newValue
            decodedOptions = opts
        }
    }
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify)
    var city: City?
    
    @Relationship(deleteRule: .nullify)
    var placeType: PlaceType?
    
    // MARK: Relationship conformance
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.placeStart)
    var startTrips: [Trip]?
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.placeEnd)
    var endTrips: [Trip]?
    
    @Relationship(deleteRule: .nullify, inverse: \Path.placeStart)
    var startPaths: [Path]?
    
    @Relationship(deleteRule: .nullify, inverse: \Path.placeEnd)
    var endPaths: [Path]?
    
    // MARK: - Init

    init(rid: Int? = nil,
         name: String = "Unset",
         cityRid: Int? = nil,
         city: City? = nil,
         address: String? = nil,
         isVirtual: Bool = false,
         placeTypeRid: Int? = nil,
         placeType: PlaceType? = nil,
         cache: Bool = false,
         archived: Bool = false,
         isFavorite: Bool = false,
         allowedVehicleRids: [Int] = [],
         allowedVehicleTypeSlugs: [String] = [],
         optionsDetails: Data? = nil,
         syncStatus: SyncStatus = .unsynced) {
        self.rid = rid
        self.name = name
        self.cityRid = cityRid
        self.city = city
        self.address = address
        self.isVirtual = isVirtual
        self.placeTypeRid = placeTypeRid
        self.placeType = placeType
        self.cache = cache
        self.archived = archived
        self.isFavorite = isFavorite
        self.allowedVehicleRids = allowedVehicleRids
        self.allowedVehicleTypeSlugs = allowedVehicleTypeSlugs
        self.options_details = optionsDetails
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: PlaceDTO) {
        var optionsData: Data? = nil
        if let options = dto.options_details {
            optionsData = try? JSONEncoder().encode(options)
        }
        
        self.init(
            rid: dto.id,
            name: dto.name,
            cityRid: dto.city_id,
            address: dto.address,
            isVirtual: dto.is_virtual ?? false,
            placeTypeRid: dto.place_type_id,
            archived: dto.archived,
            allowedVehicleRids: dto.allowed_vehicle_ids ?? [],
            allowedVehicleTypeSlugs: dto.allowed_vehicle_type_slugs ?? [],
            optionsDetails: optionsData,
            syncStatus: SyncStatus.synced
        )
    }
    
    func update(fromDto dto: PlaceDTO) {
        self.rid = dto.id
        self.name = dto.name
        self.cityRid = dto.city_id
        self.address = dto.address
        self.isVirtual = dto.is_virtual ?? false
        self.placeTypeRid = dto.place_type_id
        self.archived = dto.archived
        self.allowedVehicleRids = dto.allowed_vehicle_ids ?? []
        self.allowedVehicleTypeSlugs = dto.allowed_vehicle_type_slugs ?? []
        if let options = dto.options_details {
            self.options_details = try? JSONEncoder().encode(options)
        } else {
            self.options_details = nil
        }
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return name != "Unset" && name.count > 0 && cityRid != nil
    }
}

// MARK: - Geometry Support

enum PlaceGeometryType: String, Codable, Sendable, CaseIterable {
    case point = "Point"
    case lineString = "LineString"
    case polygon = "Polygon"
    case circle = "Circle"
}

struct PlaceGeometry: Codable, Sendable, Equatable {
    var type: PlaceGeometryType
    
    // For Point & Circle center: [longitude, latitude] or [longitude, latitude, altitude]
    var pointCoordinates: [Double]?
    
    // For LineString: [[longitude, latitude], ...]
    var lineCoordinates: [[Double]]?
    
    // For Polygon: [[[longitude, latitude], ...]]
    var polygonCoordinates: [[[Double]]]?
    
    // For Circle/Zone: radius in meters
    var radiusMeters: Double?
    
    enum CodingKeys: String, CodingKey {
        case type
        case coordinates
        case radiusMeters
        case geometry
        case pointCoordinates
        case lineCoordinates
        case polygonCoordinates
    }
    
    init(type: PlaceGeometryType, pointCoordinates: [Double]? = nil, lineCoordinates: [[Double]]? = nil, polygonCoordinates: [[[Double]]]? = nil, radiusMeters: Double? = nil) {
        self.type = type
        self.pointCoordinates = pointCoordinates
        self.lineCoordinates = lineCoordinates
        self.polygonCoordinates = polygonCoordinates
        self.radiusMeters = radiusMeters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Resilience: if a full Feature was pasted, unwrap inner geometry
        if container.contains(.geometry) {
            let inner = try container.decode(PlaceGeometry.self, forKey: .geometry)
            self = inner
            return
        }
        
        self.type = try container.decode(PlaceGeometryType.self, forKey: .type)
        self.radiusMeters = try container.decodeIfPresent(Double.self, forKey: .radiusMeters)
        
        switch type {
        case .point, .circle:
            if let coords = try? container.decode([Double].self, forKey: .coordinates) {
                self.pointCoordinates = coords
            } else {
                self.pointCoordinates = try container.decodeIfPresent([Double].self, forKey: .pointCoordinates)
            }
        case .lineString:
            if let coords = try? container.decode([[Double]].self, forKey: .coordinates) {
                self.lineCoordinates = coords
            } else {
                self.lineCoordinates = try container.decodeIfPresent([[Double]].self, forKey: .lineCoordinates)
            }
        case .polygon:
            if let coords = try? container.decode([[[Double]]].self, forKey: .coordinates) {
                self.polygonCoordinates = coords
            } else {
                self.polygonCoordinates = try container.decodeIfPresent([[[Double]]].self, forKey: .polygonCoordinates)
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(radiusMeters, forKey: .radiusMeters)
        
        switch type {
        case .point, .circle:
            try container.encodeIfPresent(pointCoordinates, forKey: .coordinates)
        case .lineString:
            try container.encodeIfPresent(lineCoordinates, forKey: .coordinates)
        case .polygon:
            try container.encodeIfPresent(polygonCoordinates, forKey: .coordinates)
        }
    }
    
    // MARK: - Convenience initializers
    static func point(latitude: Double, longitude: Double, altitude: Double? = nil) -> PlaceGeometry {
        if let alt = altitude {
            return PlaceGeometry(type: .point, pointCoordinates: [longitude, latitude, alt])
        }
        return PlaceGeometry(type: .point, pointCoordinates: [longitude, latitude])
    }
    
    static func circle(latitude: Double, longitude: Double, altitude: Double? = nil, radiusMeters: Double) -> PlaceGeometry {
        if let alt = altitude {
            return PlaceGeometry(type: .circle, pointCoordinates: [longitude, latitude, alt], radiusMeters: radiusMeters)
        }
        return PlaceGeometry(type: .circle, pointCoordinates: [longitude, latitude], radiusMeters: radiusMeters)
    }
    
    static func line(coordinates: [[Double]]) -> PlaceGeometry {
        PlaceGeometry(type: .lineString, lineCoordinates: coordinates)
    }
    
    static func polygon(coordinates: [[[Double]]]) -> PlaceGeometry {
        PlaceGeometry(type: .polygon, polygonCoordinates: coordinates)
    }
    
    // MARK: - Coordinate Helpers
    var centerLatitude: Double? {
        if let coords = pointCoordinates, coords.count >= 2 {
            return coords[1]
        }
        if let line = lineCoordinates, let first = line.first, first.count >= 2 {
            return first[1]
        }
        if let poly = polygonCoordinates, let ring = poly.first, let first = ring.first, first.count >= 2 {
            return first[1]
        }
        return nil
    }
    
    var centerLongitude: Double? {
        if let coords = pointCoordinates, coords.count >= 2 {
            return coords[0]
        }
        if let line = lineCoordinates, let first = line.first, first.count >= 2 {
            return first[0]
        }
        if let poly = polygonCoordinates, let ring = poly.first, let first = ring.first, first.count >= 2 {
            return poly.first?.first?[0]
        }
        return nil
    }
    
    var centerAltitude: Double? {
        if let coords = pointCoordinates, coords.count >= 3 {
            return coords[2]
        }
        if let line = lineCoordinates, let first = line.first, first.count >= 3 {
            return first[2]
        }
        if let poly = polygonCoordinates, let ring = poly.first, let first = ring.first, first.count >= 3 {
            return poly.first?.first?[2]
        }
        return nil
    }
    
    // MARK: - UI Helpers
    var iconName: String {
        switch type {
        case .point:
            return "mappin.and.ellipse"
        case .circle:
            return "circle.circle"
        case .lineString:
            return "point.topleft.down.to.point.bottomright.curvepath"
        case .polygon:
            return "skew"
        }
    }
    
    var typeTitle: String {
        switch type {
        case .point:
            return "Point"
        case .circle:
            return "Circle Zone"
        case .lineString:
            return "Line / Street"
        case .polygon:
            return "Polygon Zone"
        }
    }
    
    var summaryText: String {
        switch type {
        case .point:
            if let lat = centerLatitude, let lon = centerLongitude {
                return String(format: "%.4f, %.4f", lat, lon)
            }
            return "Spot"
        case .circle:
            if let lat = centerLatitude, let lon = centerLongitude {
                let r = Int(radiusMeters ?? 50)
                return String(format: "%.4f, %.4f • %dm", lat, lon, r)
            }
            return "\(Int(radiusMeters ?? 50))m radius"
        case .lineString:
            let count = lineCoordinates?.count ?? 0
            return "\(count) points"
        case .polygon:
            let count = polygonCoordinates?.first?.count ?? 0
            return "\(count) vertices"
        }
    }
}

// MARK: - Options Payload
struct PlaceOptions: Codable, Sendable {
    var reachableInTrip: Bool? = true
    var geometry: PlaceGeometry?
}

// MARK: - DTOs for Network
struct PlaceDTO: Codable, Identifiable, Sendable {
    var id: Int
    var name: String
    var city_id: Int
    var archived: Bool
    var address: String?
    var is_virtual: Bool?
    var place_type_id: Int?
    var allowed_vehicle_ids: [Int]?
    var allowed_vehicle_type_slugs: [String]?
    var options_details: PlaceOptions?
}

struct PlacePayload: Codable, InitializableWithModel {
    
    typealias Model = Place
    var name: String
    var city_id: Int
    var archived: Bool
    var address: String?
    var is_virtual: Bool
    var place_type_id: Int?
    var allowed_vehicle_ids: [Int]?
    var allowed_vehicle_type_slugs: [String]?
    var options_details: PlaceOptions?
    
    init?(from place: Place) {
        guard place.isValid(), let cityRid = place.cityRid else {
            return nil
        }
        self.name = place.name
        self.city_id = cityRid
        self.archived = place.archived
        self.address = place.address
        self.is_virtual = place.isVirtual
        self.place_type_id = place.placeTypeRid ?? place.placeType?.rid
        self.allowed_vehicle_ids = place.allowedVehicleRids.isEmpty ? nil : place.allowedVehicleRids
        self.allowed_vehicle_type_slugs = place.allowedVehicleTypeSlugs.isEmpty ? nil : place.allowedVehicleTypeSlugs
        self.options_details = place.decodedOptions
    }
}

struct PlaceEditor: CachableModel, EditorProtocol {
    var rid: Int?
    var slug: String?
    var name: String
    var cityRid: Int?
    var city: City?
    var address: String?
    var isVirtual: Bool = false
    var placeTypeRid: Int?
    var placeType: PlaceType?
    var cache: Bool
    var archived: Bool
    var isFavorite: Bool
    var allowedVehicleRids: [Int]
    var allowedVehicleTypeSlugs: [String]
    var decodedOptions: PlaceOptions?
    
    var geometry: PlaceGeometry? {
        get {
            decodedOptions?.geometry
        }
        set {
            if decodedOptions == nil { decodedOptions = PlaceOptions() }
            decodedOptions?.geometry = newValue
        }
    }
    
    typealias Model = Place
    
    init(from place: Place) {
        self.rid = place.rid
        self.name = place.name
        self.cityRid = place.cityRid
        self.city = place.city
        self.address = place.address
        self.isVirtual = place.isVirtual
        self.placeTypeRid = place.placeTypeRid
        self.placeType = place.placeType
        self.cache = place.cache
        self.archived = place.archived
        self.isFavorite = place.isFavorite
        self.allowedVehicleRids = place.allowedVehicleRids
        self.allowedVehicleTypeSlugs = place.allowedVehicleTypeSlugs
        self.decodedOptions = place.decodedOptions
    }
    
    func apply(to place: Place) {
        place.rid = self.rid
        place.name = self.name
        place.cityRid = self.cityRid
        place.address = self.address
        place.isVirtual = self.isVirtual
        place.placeTypeRid = self.placeTypeRid ?? self.placeType?.rid
        place.placeType = self.placeType
        place.cache = self.cache
        place.archived = self.archived
        place.isFavorite = self.isFavorite
        place.allowedVehicleRids = self.allowedVehicleRids
        place.allowedVehicleTypeSlugs = self.allowedVehicleTypeSlugs
        place.decodedOptions = self.decodedOptions
    }
}
