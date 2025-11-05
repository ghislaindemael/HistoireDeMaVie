//
//  City.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation
import SwiftData

@Model
final class City: CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    @Attribute(.unique) var slug: String
    @Attribute(.unique) var name: String
    var countryRid: Int?

    var cache: Bool = true
    var archived: Bool = false
    var syncStatusRaw: String = SyncStatus.local.rawValue
    
    typealias Payload = CityPayload
    typealias DTO = CityDTO
    typealias Editor = CityEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var country: Country?
    
    // MARK: Relationship conformance
    
    @Relationship(deleteRule: .nullify, inverse: \Place.city)
    var places: [Place]?
    
    // MARK: - Init
    init(
        rid: Int? = nil,
        slug: String = "unset",
        name: String = "Unset",
        countryRid: Int? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .local
    ) {
        self.slug = slug
        self.name = name
        self.rid = rid
        self.countryRid = countryRid
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    // MARK: - Convenience from DTO
    convenience init(fromDto dto: CityDTO) {
        self.init()
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.countryRid = dto.country_id
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func update(fromDto dto: CityDTO) {
        self.slug = dto.slug
        self.name = dto.name
        self.countryRid = dto.country_id
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        guard slug.isNotUnset(), name.isNotUnset() else { return false }
        return countryRid != nil
    }
}

struct CityDTO: Codable, Identifiable, Sendable {
    var id: Int
    var slug: String
    var name: String
    var country_id: Int
    var cache: Bool
    var archived: Bool
}

struct CityPayload: Codable, InitializableWithModel {
    typealias Model = City
    var slug: String
    var name: String
    var country_id: Int
    var cache: Bool
    var archived: Bool
    
    init?(from city: City) {
        guard city.isValid(),
              let countryRid = city.countryRid else {
            return nil
        }
        
        self.slug = city.slug
        self.name = city.name
        self.country_id = countryRid
        self.cache = city.cache
        self.archived = city.archived
    }
}

struct CityEditor: CachableModel, EditorProtocol {
    var slug: String?
    var name: String?
    var countryRid: Int?
    var country: Country?
    var cache: Bool
    var archived: Bool
    
    init(from city: City) {
        self.slug = city.slug
        self.name = city.name
        self.countryRid = city.countryRid
        self.country = city.country
        self.cache = city.cache
        self.archived = city.archived
    }
    
    func apply(to city: City) {
        if let slug = self.slug { city.slug = slug }
        if let name = self.name { city.name = name }
        
        if country != nil {
            city.setCountry(country)
        } else {
            city.countryRid = self.countryRid
        }
        
        city.cache = self.cache
        city.archived = self.archived
    }
}

