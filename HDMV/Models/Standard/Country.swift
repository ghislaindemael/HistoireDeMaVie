//
//  Country.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation
import SwiftData

import Foundation
import SwiftData

@Model
final class Country: CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    var slug: String
    var name: String
    var cache: Bool = true
    var archived: Bool = false
    var syncStatusRaw: String = SyncStatus.local.rawValue
    
    typealias Payload = CountryPayload
    typealias DTO = CountryDTO
    typealias Editor = CountryEditor
    
    // MARK: Relationship conformance
    
    @Relationship(deleteRule: .nullify, inverse: \City.country)
    var cities: [City]?
    
    // MARK: Init
    
    init(
        slug: String,
        name: String,
        rid: Int? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .local
    ) {
        self.slug = slug
        self.name = name
        self.rid = rid
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    func isValid() -> Bool {
        guard name.isNotUnset()  else {
            return false
        }
        return true
    }
    
    convenience init(fromDto dto: CountryDTO) {
        self.init(slug: dto.slug, name: dto.name, rid: dto.id, cache: dto.cache, archived: dto.archived, syncStatus: .synced)
    }
    
    func update(fromDto dto: CountryDTO) {
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
}

struct CountryDTO: Codable, Identifiable, Sendable {
    var id: Int
    var slug: String
    var name: String
    var cache: Bool = true
    var archived: Bool = false
    
}

struct CountryPayload: Codable, InitializableWithModel {
    typealias Model = Country
    var slug: String
    var name: String
    var cache: Bool
    var archived: Bool
    
    init?(from country: Country) {
        guard country.isValid() else { return nil }
        self.slug = country.slug
        self.name = country.name
        self.cache = country.cache
        self.archived = country.archived
    }
}

struct CountryEditor: CachableModel, EditorProtocol {
    var rid: Int?
    var slug: String?
    var name: String?
    var cache: Bool
    var archived: Bool
    
    typealias Model = Country
    
    init(from country: Country) {
        self.rid = country.rid
        self.slug = country.slug
        self.name = country.name
        self.cache = country.cache
        self.archived = country.archived
    }
    
    func apply(to country: Country) {
        country.rid = self.rid
        country.slug = self.slug ?? country.slug
        country.name = self.name ?? country.name
        country.cache = self.cache
        country.archived = self.archived
    }
}
