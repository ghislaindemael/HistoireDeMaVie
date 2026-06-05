//
//  DataActivityOption.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftData

enum DataActivityOptionType: String, Codable {
    case boolean
    case integer
    case decimal
    case range
    case rating
    case text
    case dropdown
    case person
}

struct DataActivityOptionChoice: Codable, Equatable, Hashable {
    var slug: String
    var label: String
    var icon: String?
    var archived: Bool?
}

struct DataActivityOptionConfig: Codable, Equatable {
    var multiselect: Bool?
    var choices: [DataActivityOptionChoice]?
    var defaultValue: String?
    var min: Double?
    var max: Double?
    var step: Double?
    var layoutNode: ActivityLayoutNode?
}

@Model
final class DataActivityOption: Identifiable, Hashable, CatalogueModel {
    
    var rid: Int?
    var slug: String
    var name: String
    var typeRaw: String
    var configRaw: Data? // JSONB stored as Data
    var cache: Bool = true
    var archived: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \DataActivityOptionMapping.option)
    var mappings: [DataActivityOptionMapping]? = []
    
    typealias Payload = DataActivityOptionPayload
    typealias DTO = DataActivityOptionDTO
    typealias Editor = DataActivityOptionEditor
    
    init(
        rid: Int? = nil,
        slug: String = "unset",
        name: String = "Unset",
        type: DataActivityOptionType = .text,
        config: DataActivityOptionConfig? = nil,
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
    
    var type: DataActivityOptionType {
        get { DataActivityOptionType(rawValue: typeRaw) ?? .text }
        set { typeRaw = newValue.rawValue }
    }
    
    var config: DataActivityOptionConfig? {
        get {
            guard let data = configRaw else { return nil }
            return try? JSONDecoder().decode(DataActivityOptionConfig.self, from: data)
        }
        set {
            if let newConfig = newValue {
                configRaw = try? JSONEncoder().encode(newConfig)
            } else {
                configRaw = nil
            }
        }
    }
    
    convenience init(fromDto dto: DataActivityOptionDTO) {
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
    
    func update(fromDto dto: DataActivityOptionDTO) {
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

struct DataActivityOptionDTO: Codable, Identifiable {
    let id: Int
    let slug: String
    let name: String
    let type: String
    let config: DataActivityOptionConfig?
}

struct DataActivityOptionPayload: Codable, InitializableWithModel {
    typealias Model = DataActivityOption
    
    let slug: String
    let name: String
    let type: String
    let config: DataActivityOptionConfig?
    
    init?(from model: DataActivityOption) {
        guard model.isValid() else { return nil }
        self.slug = model.slug
        self.name = model.name
        self.type = model.typeRaw
        self.config = model.config
    }
}

struct DataActivityOptionEditor: CachableModel, EditorProtocol {
    var slug: String
    var name: String
    var type: DataActivityOptionType
    var config: DataActivityOptionConfig?
    var cache: Bool = true
    var archived: Bool = false
    
    typealias Model = DataActivityOption
    
    init(from model: DataActivityOption) {
        self.slug = model.slug
        self.name = model.name
        self.type = model.type
        self.config = model.config
        self.cache = model.cache
        self.archived = model.archived
    }
    
    func apply(to model: DataActivityOption) {
        model.slug = self.slug
        model.name = self.name
        model.type = self.type
        model.config = self.config
        model.cache = self.cache
        model.archived = self.archived
    }
}

extension DataActivityOption: Equatable {
    static func == (lhs: DataActivityOption, rhs: DataActivityOption) -> Bool {
        lhs.id == rhs.id
    }
}
