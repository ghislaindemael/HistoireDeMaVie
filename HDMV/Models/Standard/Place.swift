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
    
    var rid: Int?
    var name: String
    var cityRid: Int?
    @Relationship(deleteRule: .nullify)
    var relCity: City? {
        didSet {
            self.cityRid = relCity.rid
        }
    }
    var cache: Bool = true
    var archived: Bool = false
    var syncStatusRaw: String = SyncStatus.local.rawValue
    
    typealias DTO = PlaceDTO
    typealias Payload = PlacePayload
    typealias Editor = PlaceEditor
    
    var city: City? {
        get {
            if let city = relCity { return city }
            guard let rid = cityRid, let ctx = RelationResolver.context else { return nil }
            let descriptor = FetchDescriptor<City>(predicate: #Predicate { $0.rid == rid })
            return try? ctx.fetch(descriptor).first
        }
        set {
            relCity = newValue
            if newValue?.rid != cityRid {
                cityRid = newValue?.rid
            }
        }
    }

    init(rid: Int? = nil,
         name: String = "Unset",
         cityRid: Int? = nil,
         relCity: City? = nil,
         cache: Bool = true,
         archived: Bool = false,
         syncStatus: SyncStatus = .local) {
        self.rid = rid
        self.name = name
        self.cityRid = cityRid
        self.relCity = relCity
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: PlaceDTO) {
        self.init(
            rid: dto.id,
            name: dto.name,
            cityRid: dto.city_id,
            cache: dto.cache,
            archived: dto.archived,
            syncStatus: SyncStatus.synced
        )
    }
    
    func update(fromDto dto: PlaceDTO) {
        self.rid = dto.id
        self.name = dto.name
        self.cityRid = dto.city_id
        self.cache = dto.cache
        self.archived = dto.archived
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
    var cache: Bool
    var archived: Bool
}

struct PlacePayload: Codable, InitializableWithModel {
    
    typealias Model = Place
    var name: String
    var city_id: Int
    var cache: Bool
    var archived: Bool
    
    init?(from place: Place) {
        guard place.isValid(),
              let cityRid = place.city?.rid ?? place.cityRid else {
            return nil
        }
        self.name = place.name
        self.city_id = cityRid
        self.cache = place.cache
        self.archived = place.archived
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
    
    typealias Model = Place
    
    init(from place: Place) {
        self.rid = place.rid
        self.name = place.name
        self.cityRid = place.cityRid
        self.city = place.city
        self.cache = place.cache
        self.archived = place.archived
    }
    
    func apply(to place: Place) {
        place.rid = self.rid
        place.name = self.name
        
        if let selectedCity = self.city {
            place.relCity = selectedCity
            place.cityRid = selectedCity.rid
        }
        
        place.cache = self.cache
        place.archived = self.archived
    }
}
