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
    var typeSlug: String?
    var type: VehicleType? {
        get { VehicleType(rawValue: typeSlug ?? "unset") ?? .unset }
        set { if let unwrappedType = newValue {
            typeSlug = unwrappedType.rawValue
        } else {
            typeSlug = nil
        } }
    }
    var cityRid: Int?
    @Relationship
    var city: City? {
        didSet {
            self.cityRid = city.rid
        }
    }
    var cache: Bool = true
    var archived: Bool = false
    var syncStatusRaw: String = SyncStatus.local.rawValue
    
    typealias DTO = VehicleDTO
    typealias Payload = VehiclePayload
    
    init(rid: Int? = nil,
         name: String? = nil,
         typeSlug: String? = nil,
         type: VehicleType? = nil,
         cityRid: Int? = nil,
         city: City? = nil,
         cache: Bool = true,
         archived: Bool = false,
         syncStatus: SyncStatus = .local) {
        self.rid = rid
        self.name = name
        self.typeSlug = typeSlug
        self.type = type
        self.cityRid = cityRid
        self.city = city
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: VehicleDTO) {
        self.init(
            rid: dto.id,
            name: dto.name,
            typeSlug: dto.type_slug,
            cityRid: dto.city_id,
            cache: dto.cache,
            archived: dto.archived,
            syncStatus: SyncStatus.synced
        )
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
        return name != nil && typeSlug != nil
    }
    
    var label: String {
        var components: [String] = []
        
        if let typeIcon = type?.icon {
            components.append(typeIcon)
        } else {
            components.append("❓")
        }
        
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
    var city_id: Int
    var cache: Bool
    var archived: Bool
    
    init?(from vehicle: Vehicle) {
        guard vehicle.isValid(),
              let name = vehicle.name,
              let typeSlug = vehicle.typeSlug,
              let cityRid = vehicle.city?.rid ?? vehicle.cityRid else {
            return nil
        }
        self.name = name
        self.type_slug = typeSlug
        self.city_id = cityRid
        self.cache = vehicle.cache
        self.archived = vehicle.archived
    }
}

struct VehicleEditor: CachableModel {
    var rid: Int?
    var name: String?
    var typeSlug: String?
    var type: VehicleType {
        get { VehicleType(rawValue: typeSlug ?? "unset") ?? .unset}
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
            vehicle.city = selectedCity
            vehicle.cityRid = selectedCity.rid
        } else {
            vehicle.cityRid = self.cityRid
        }
        
        vehicle.cache = self.cache
        vehicle.archived = self.archived
    }
}
