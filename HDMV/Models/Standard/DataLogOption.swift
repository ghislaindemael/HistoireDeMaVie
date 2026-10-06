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
    var slug: String
    var name: String
    var typeRaw: String
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
        slug: String = "unset",
        name: String = "Unset",
        type: DataLogOptionType = .text,
        config: DataLogOptionConfig? = nil,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.slug = slug
        self.name = name
        self.typeRaw = type.rawValue
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
        
        if let configDict = dto.config {
            self.configRaw = try? JSONEncoder().encode(configDict)
        }
        
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataLogOptionDTO) {
        self.slug = dto.slug
        self.name = dto.name
        self.typeRaw = dto.type
        
        if let configDict = dto.config {
            self.configRaw = try? JSONEncoder().encode(configDict)
        }
        
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return slug != "unset" && name != "Unset"
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
    let config: DataLogOptionConfig?
}

struct DataLogOptionPayload: Codable, InitializableWithModel {
    typealias Model = DataLogOption
    
    let slug: String
    let name: String
    let type: String
    let config: DataLogOptionConfig?
    
    init?(from model: DataLogOption) {
        guard model.isValid() else { return nil }
        self.slug = model.slug
        self.name = model.name
        self.type = model.typeRaw
        self.config = model.config
    }
}

struct DataLogOptionEditor: CachableModel, EditorProtocol {
    var slug: String
    var name: String
    var type: DataLogOptionType
    var config: DataLogOptionConfig?
    var cache: Bool = true
    var archived: Bool = false
    
    typealias Model = DataLogOption
    
    init(from model: DataLogOption) {
        self.slug = model.slug
        self.name = model.name
        self.type = model.type
        self.config = model.config
        self.cache = model.cache
        self.archived = model.archived
    }
    
    func apply(to model: DataLogOption) {
        model.slug = self.slug
        model.name = self.name
        model.type = self.type
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
