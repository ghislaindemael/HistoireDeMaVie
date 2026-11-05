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
final class Country: CatalogueModel, EditableModel {
    
    @Attribute(.unique) var rid: Int?
    @Attribute(.unique) var slug: String
    @Attribute(.unique) var name: String
    var timezone: String?
    var cache: Bool = false
    var archived: Bool = false
    var syncStatusRaw: String = SyncStatus.unsynced.rawValue
    
    typealias Payload = CountryPayload
    typealias DTO = CountryDTO
    typealias Editor = CountryEditor
    
    // MARK: Relationship conformance
    
    @Relationship(deleteRule: .nullify, inverse: \City.country)
    var cities: [City]?
    
    // MARK: Init
    
    init(
        slug: String = "!unset",
        name: String = "Unset",
        rid: Int? = nil,
        timezone: String? = nil,
        cache: Bool = false,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.slug = slug
        self.name = name
        self.rid = rid
        self.timezone = timezone ?? Self.defaultTimeZoneIdentifier(forSlug: slug)
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    func isValid() -> Bool {
        guard name.isNotUnset(), slug.isNotUnset() else {
            return false
        }
        return true
    }
    
    convenience init(fromDto dto: CountryDTO) {
        self.init(
            slug: dto.slug,
            name: dto.name,
            rid: dto.id,
            timezone: dto.timezone ?? Self.defaultTimeZoneIdentifier(forSlug: dto.slug),
            archived: dto.archived,
            syncStatus: .synced
        )
    }
    
    func update(fromDto dto: CountryDTO) {
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        if let dtoTz = dto.timezone, !dtoTz.isEmpty {
            self.timezone = dtoTz
        } else if self.timezone == nil {
            self.timezone = Self.defaultTimeZoneIdentifier(forSlug: dto.slug)
        }
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    var effectiveTimeZoneIdentifier: String? {
        if let tz = timezone, !tz.isEmpty {
            return tz
        }
        return Self.defaultTimeZoneIdentifier(forSlug: slug)
    }
    
    var resolvedTimeZone: TimeZone? {
        guard let id = effectiveTimeZoneIdentifier else { return nil }
        return TimeZone(identifier: id)
    }
    
    static func defaultTimeZoneIdentifier(forSlug slug: String) -> String? {
        switch slug.lowercased() {
        case "england", "wales", "uk", "unitedkingdom":
            return "Europe/London"
        case "france":
            return "Europe/Paris"
        case "switzerland", "ch":
            return "Europe/Zurich"
        case "italy":
            return "Europe/Rome"
        case "egypt":
            return "Africa/Cairo"
        case "japan":
            return "Asia/Tokyo"
        case "netherlands":
            return "Europe/Amsterdam"
        case "unitedstates", "usa":
            return "America/New_York"
        case "tunisia":
            return "Africa/Tunis"
        case "austria":
            return "Europe/Vienna"
        case "germany", "allemagne":
            return "Europe/Berlin"
        case "monaco":
            return "Europe/Monaco"
        case "vatican":
            return "Europe/Vatican"
        default:
            return nil
        }
    }
    
    var sortedCities: [City] {
        cities?.sorted { $0.slug < $1.slug } ?? []
    }
    
    var rootCities: [City] {
        sortedCities.filter { $0.parentCity == nil }
    }
}

struct CountryDTO: Codable, Identifiable, Sendable {
    var id: Int
    var slug: String
    var name: String
    var timezone: String? = nil
    var archived: Bool = false
}

struct CountryPayload: Codable, InitializableWithModel {
    typealias Model = Country
    var slug: String
    var name: String
    var timezone: String?
    var archived: Bool
    
    init?(from country: Country) {
        guard country.isValid() else { return nil }
        self.slug = country.slug
        self.name = country.name
        self.timezone = country.effectiveTimeZoneIdentifier
        self.archived = country.archived
    }
}

struct CountryEditor: CachableModel, EditorProtocol {
    var rid: Int?
    var slug: String
    var name: String
    var timezone: String?
    var cache: Bool
    var archived: Bool
    
    typealias Model = Country
    
    init(from country: Country) {
        self.rid = country.rid
        self.slug = country.slug
        self.name = country.name
        self.timezone = country.effectiveTimeZoneIdentifier
        self.cache = country.cache
        self.archived = country.archived
    }
    
    func apply(to country: Country) {
        country.rid = self.rid
        country.slug = self.slug
        country.name = self.name
        country.timezone = (self.timezone?.isEmpty == true) ? nil : self.timezone
        country.cache = self.cache
        country.archived = self.archived
    }
}
