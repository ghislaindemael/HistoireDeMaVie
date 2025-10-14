//
//  Country.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation
import SwiftData

@available(iOS 26.0, macOS 26.0, *)
@Model
final class Country: CatalogueModel {
    
    typealias Payload = CountryPayload
    
    var slug: String?
    var name: String?
    
    // MARK: - Initializers
    
    required init(
        rid: Int? = nil,
        slug: String? = nil,
        name: String? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .local
    ) {
        self.slug = slug
        self.name = name
        
        super.init(
            rid: rid,
            cache: cache,
            archived: archived,
            syncStatusRaw: syncStatus.rawValue
        )
    }
    
    convenience init(fromDto dto: CountryDTO) {
        self.init(
            rid: dto.id,
            slug: dto.slug,
            name: dto.name,
            cache: dto.cache,
            archived: dto.archived,
            syncStatus: .synced
        )
    }
    
    override func isValid() -> Bool {
        return name != nil && slug != nil
    }
    
    func update(fromDto dto: CountryDTO) {
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
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
        guard country.isValid(),
              let name = country.name,
              let slug = country.slug
        else { return nil }
        
        self.name = name
        self.slug = slug
        self.cache = country.cache
        self.archived = country.archived
    }
}

struct CountryEditor: CachableModel {
    
    var rid: Int? = nil
    var slug: String?
    var name: String?
    var cache: Bool
    var archived: Bool
    
    init(from country: Country) {
        self.rid = country.rid
        self.slug = country.slug
        self.name = country.name
        self.cache = country.cache
        self.archived = country.archived

    }
    
    func apply(to country: Country) {
        country.rid = self.rid
        country.slug = self.slug
        country.name = self.name
        country.cache = self.cache
        country.archived = self.archived
    }
    
}

