//
//  DataLogOption.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

enum DataLogOptionType: String, Codable {
    case boolean
    case integer
    case decimal
    case range
    case rating
    case text
    case dropdown
    case person
    case time
}

struct DataLogOptionChoice: Codable, Equatable, Hashable {
    var slug: String
    var label: String
    var icon: String?
    var archived: Bool?
}

struct DataLogOptionConfig: Codable, Equatable {
    var multiselect: Bool?
    var choices: [DataLogOptionChoice]?
    var defaultValue: String?
    var min: Double?
    var max: Double?
    var step: Double?
    var layoutNode: ActivityLayoutNode?
    var replacesActivityName: Bool?
    
    // Conditionals
    var dependsOnSlug: String?
    var showIfValues: [String]?
    var hideIfValues: [String]?
}

@Model
final class DataLogOption: Identifiable, Hashable, CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    @Attribute(.unique) var slug: String
    var name: String
    var typeRaw: String
    var category: String?
    var configRaw: Data? // JSONB stored as Data
    var cache: Bool = true
    var archived: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \DataLogOptionMapping.option)
    var mappings: [DataLogOptionMapping]? = []
    
    typealias Payload = DataLogOptionPayload
    typealias DTO = DataLogOptionDTO
    typealias Editor = DataLogOptionEditor
    
    init(
        rid: Int? = nil,
        slug: String = "!unset",
        name: String = "Unset",
        type: DataLogOptionType = .text,
        category: String? = nil,
        config: DataLogOptionConfig? = nil,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.slug = slug
        self.name = name
        self.typeRaw = type.rawValue
        self.category = category
        if let config = config {
            self.configRaw = try? JSONEncoder().encode(config)
        }
        self.syncStatus = syncStatus
    }
    
    var type: DataLogOptionType {
        get { DataLogOptionType(rawValue: typeRaw) ?? .text }
        set { typeRaw = newValue.rawValue }
    }
    
    var config: DataLogOptionConfig? {
        get {
            guard let data = configRaw else { return nil }
            return try? JSONDecoder().decode(DataLogOptionConfig.self, from: data)
        }
        set {
            if let newConfig = newValue {
                configRaw = try? JSONEncoder().encode(newConfig)
            } else {
                configRaw = nil
            }
        }
    }
    
    convenience init(fromDto dto: DataLogOptionDTO) {
        self.init()
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.typeRaw = dto.type
        self.category = dto.category
        
        if let configDict = dto.config {
            self.configRaw = try? JSONEncoder().encode(configDict)
        }
        
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataLogOptionDTO) {
        self.slug = dto.slug
        self.name = dto.name
        self.typeRaw = dto.type
        self.category = dto.category
        
        if let configDict = dto.config {
            self.configRaw = try? JSONEncoder().encode(configDict)
        }
        
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return slug.isNotUnset() && name.isNotUnset()
    }
    
    var hasUnsyncedChanges: Bool {
        return self.syncStatus != .synced
    }
}

// MARK: - DTO and Payload

struct DataLogOptionDTO: Codable, Identifiable {
    let id: Int
    let slug: String
    let name: String
    let type: String
    let category: String?
    let config: DataLogOptionConfig?
    
    enum CodingKeys: String, CodingKey {
        case id, slug, name, type, category, config
    }
    
    init(id: Int, slug: String, name: String, type: String, category: String? = nil, config: DataLogOptionConfig? = nil) {
        self.id = id
        self.slug = slug
        self.name = name
        self.type = type
        self.category = category
        self.config = config
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.config = try container.decodeIfPresent(DataLogOptionConfig.self, forKey: .config)
    }
}

struct DataLogOptionPayload: Codable, InitializableWithModel {
    typealias Model = DataLogOption
    
    let slug: String
    let name: String
    let type: String
    let category: String?
    let config: DataLogOptionConfig?
    
    enum CodingKeys: String, CodingKey {
        case slug, name, type, category, config
    }
    
    init?(from model: DataLogOption) {
        guard model.isValid() else { return nil }
        self.slug = model.slug
        self.name = model.name
        self.type = model.typeRaw
        self.category = model.category
        self.config = model.config
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(slug, forKey: .slug)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        if let category = category {
            try container.encode(category, forKey: .category)
        }
        if let config = config {
            try container.encode(config, forKey: .config)
        }
    }
}

struct DataLogOptionEditor: CachableModel, EditorProtocol {
    var slug: String
    var name: String
    var type: DataLogOptionType
    var category: String?
    var config: DataLogOptionConfig?
    var cache: Bool = true
    var archived: Bool = false
    
    typealias Model = DataLogOption
    
    init(from model: DataLogOption) {
        self.slug = model.slug
        self.name = model.name
        self.type = model.type
        self.category = model.category
        self.config = model.config
        self.cache = model.cache
        self.archived = model.archived
    }
    
    func apply(to model: DataLogOption) {
        if !model.slug.isNotUnset() || model.slug == "!unset" {
            model.slug = self.slug
        }
        model.name = self.name
        model.type = self.type
        model.category = self.category
        model.config = self.config
        model.cache = self.cache
        model.archived = self.archived
    }
}

extension DataLogOption: Equatable {
    static func == (lhs: DataLogOption, rhs: DataLogOption) -> Bool {
        lhs.id == rhs.id
    }
}
