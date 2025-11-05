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
    var slug: String?
    var name: String?
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
    
    // MARK: - Initializer
    init(
        rid: Int? = nil,
        slug: String? = nil,
        name: String? = nil,
        country: Country? = nil,
        countryRid: Int? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .local
    ) {
        self.slug = slug
        self.name = name
        self.rid = rid
        self.country = country
        self.countryRid = countryRid
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    // MARK: - Convenience from DTO
    convenience init(fromDto dto: CityDTO) {
        self.init(
            rid: dto.id,
            slug: dto.slug,
            name: dto.name,
            countryRid: dto.country_id,
            cache: dto.cache,
            archived: dto.archived,
            syncStatus: SyncStatus.synced
        )
    }
    
    func update(fromDto dto: CityDTO) {
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.countryRid = dto.country_id
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        guard let slug = slug, !slug.isEmpty,
              let name = name, !name.isEmpty else {
            return false
        }
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
              let slug = city.slug,
              let name = city.name,
              let countryRid = city.countryRid else {
            return nil
        }
        
        self.slug = slug
        self.name = name
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
        
        if city.country === self.country {
                print(" apply: No change. 'city.country' is already 'self.country'.")
            } else {
                print(" apply: 'country' has changed. 'didSet' will fire.")
            }
        
        city.country = self.country
        city.cache = self.cache
        city.archived = self.archived
    }
}

