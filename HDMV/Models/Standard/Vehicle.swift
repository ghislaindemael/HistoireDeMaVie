//
//  Vehicle.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation
import SwiftData

@Model
final class Vehicle: CatalogueModel {
    @Attribute(.unique) var rid: Int?
    var name: String?
    var typeSlug: String
    var cityRid: Int?
    
    var cache: Bool = true
    var archived: Bool = false
    var syncStatusRaw: String = SyncStatus.local.rawValue
    
    typealias DTO = VehicleDTO
    typealias Payload = VehiclePayload
    typealias Editor = VehicleEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var city: City?
    
    // MARK: Relationship conformance
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.vehicle)
    var trips: [Trip]?
    
    // MARK: Init
    
    init(rid: Int? = nil,
         name: String? = nil,
         typeSlug: String = "unset",
         type: VehicleType = .unset,
         cityRid: Int? = nil,
         city: City? = nil,
         cache: Bool = true,
         archived: Bool = false,
         syncStatus: SyncStatus = .local) {
        self.rid = rid
        self.name = name
        self.typeSlug = typeSlug
        if type != .unset {
            self.type = type
        }
        self.cityRid = cityRid
        self.city = city
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: VehicleDTO) {
        self.init()
        self.name = dto.name
        self.typeSlug = dto.type_slug
        self.cityRid = dto.city_id
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func update(fromDto dto: VehicleDTO) {
        self.rid = dto.id
        self.name = dto.name
        self.typeSlug = dto.type_slug
        self.cityRid = dto.city_id
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return name != nil && typeSlug.isNotUnset()
    }
    
    var label: String {
        var components: [String] = []
        
        components.append(type.icon)

        if let cityName = city?.name, !cityName.isEmpty {
            components.append(cityName)
        } else if cityRid != nil {
            components.append("(\(cityRid!))")
        }
        
        if let vehicleName = name, !vehicleName.isEmpty {
            components.append(vehicleName)
        } else {
            components.append("Unnamed")
        }
        
        return components.joined(separator: " - ")
    }
    
    // MARK: Computed properties
    
    var type: VehicleType {
        get {
            VehicleType(rawValue: typeSlug) ?? .unset
        }
        set {
            typeSlug = newValue.rawValue
        }
    }
}


// MARK: - DTOs for Network
struct VehicleDTO: Codable, Identifiable, Sendable {
    var id: Int
    var name: String
    var type_slug: String
    var city_id: Int?
    var cache: Bool
    var archived: Bool
}

struct VehiclePayload: Codable, InitializableWithModel {
    
    typealias Model = Vehicle
    var name: String
    var type_slug: String
    var city_id: Int?
    var cache: Bool
    var archived: Bool
    
    init?(from vehicle: Vehicle) {
        guard vehicle.isValid(),
              let name = vehicle.name
        else {
            return nil
        }
        self.name = name
        self.type_slug = vehicle.typeSlug
        self.city_id = vehicle.cityRid
        self.cache = vehicle.cache
        self.archived = vehicle.archived
    }
}

struct VehicleEditor: CachableModel, EditorProtocol {
    var rid: Int?
    var name: String?
    var typeSlug: String
    var type: VehicleType {
        get { VehicleType(rawValue: typeSlug) ?? .unset}
        set { typeSlug = newValue.rawValue }
    }
    var cityRid: Int?
    var city: City?
    var cache: Bool
    var archived: Bool
    
    init(from vehicle: Vehicle) {
        self.rid = vehicle.rid
        self.name = vehicle.name
        self.typeSlug = vehicle.typeSlug
        self.cityRid = vehicle.cityRid
        self.city = vehicle.city
        self.cache = vehicle.cache
        self.archived = vehicle.archived
    }
    
    func apply(to vehicle: Vehicle) {
        vehicle.rid = self.rid
        vehicle.name = name
        vehicle.typeSlug = self.typeSlug
        vehicle.type = self.type
        
        if let selectedCity = self.city {
            vehicle.setCity(selectedCity)
        } else {
            vehicle.cityRid = self.cityRid
        }
        
        vehicle.cache = self.cache
        vehicle.archived = self.archived
    }
}
