//
//  PlaceType.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2026.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class PlaceType: CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    var name: String
    @Attribute(.unique) var slug: String
    var icon: String?
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    @Relationship(deleteRule: .nullify, inverse: \Place.placeType)
    var places: [Place]? = []
    
    typealias Payload = PlaceTypePayload
    typealias DTO = PlaceTypeDTO
    typealias Editor = PlaceTypeEditor
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        slug: String = "unset",
        icon: String? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.slug = slug
        self.icon = icon
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: PlaceTypeDTO) {
        self.init(
            rid: dto.id,
            name: dto.name,
            slug: dto.slug,
            icon: dto.icon,
            cache: true,
            archived: dto.archived,
            syncStatus: .synced
        )
    }
    
    func update(fromDto dto: PlaceTypeDTO) {
        self.rid = dto.id
        self.name = dto.name
        self.slug = dto.slug
        self.icon = dto.icon
        self.archived = dto.archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return name.isNotUnset() && slug.isNotUnset()
    }
}

// MARK: - Data Transfer Objects (DTOs)

struct PlaceTypeDTO: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let slug: String
    let icon: String?
    let archived: Bool
}

struct PlaceTypePayload: Codable, InitializableWithModel {
    let name: String
    let slug: String
    let icon: String?
    let archived: Bool
    
    typealias Model = PlaceType
    
    init?(from type: PlaceType) {
        guard type.isValid() else { return nil }
        self.name = type.name
        self.slug = type.slug
        self.icon = type.icon
        self.archived = type.archived
    }
}

struct PlaceTypeEditor: CachableModel, EditorProtocol {
    var rid: Int?
    var slug: String?
    var name: String
    var icon: String?
    var cache: Bool = true
    var archived: Bool = false
    
    typealias Model = PlaceType
    
    init(from type: PlaceType) {
        self.rid = type.rid
        self.name = type.name
        self.slug = type.slug
        self.icon = type.icon
        self.cache = type.cache
        self.archived = type.archived
    }
    
    func apply(to type: PlaceType) {
        type.rid = self.rid
        type.name = self.name
        type.slug = self.slug ?? type.slug
        type.icon = self.icon
        type.cache = self.cache
        type.archived = self.archived
    }
}

extension PlaceType: Equatable {
    static func == (lhs: PlaceType, rhs: PlaceType) -> Bool {
        lhs.id == rhs.id
    }
}
