//
//  DataMediaItem.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation
import SwiftData

@Model
final class DataMediaItem: Identifiable, Hashable, CatalogueModel, TreeSelectable {
    
    var rid: Int?
    var name: String
    
    var parentRid: Int?
    var parent: DataMediaItem? {
        didSet {
            parentRid = parent?.rid
        }
    }
    
    @Relationship(deleteRule: .nullify, inverse: \DataMediaItem.parent)
    var children: [DataMediaItem] = []
    
    var selectable: Bool = true
    var archived: Bool = false
    var cache: Bool = true
    var icon: String?
    
    // Feature specific to DataMediaItem: tracking uncountable consumptions (e.g. watched Shrek 8 times)
    var untrackedConsumptions: Int = 0
    
    // For metadata like 'media_type', 'author' etc. we can store a raw JSON string or specific fields
    // Keeping it simple as a dictionary representation
    var metadataString: String?
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = DataMediaItemPayload
    typealias DTO = DataMediaItemDTO
    typealias Editor = DataMediaItemEditor
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        parentRid: Int? = nil,
        icon: String? = nil,
        selectable: Bool = true,
        archived: Bool = false,
        untrackedConsumptions: Int = 0,
        metadataString: String? = nil,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.parentRid = parentRid
        self.icon = icon
        self.selectable = selectable
        self.archived = archived
        self.untrackedConsumptions = untrackedConsumptions
        self.metadataString = metadataString
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: DataMediaItemDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.selectable = dto.selectable
        self.archived = dto.archived
        self.untrackedConsumptions = dto.untracked_consumptions
        if let md = dto.metadata, let mdData = try? JSONEncoder().encode(md) {
            self.metadataString = String(data: mdData, encoding: .utf8)
        }
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataMediaItemDTO) {
        self.name = dto.name
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.selectable = dto.selectable
        self.archived = dto.archived
        self.untrackedConsumptions = dto.untracked_consumptions
        if let md = dto.metadata, let mdData = try? JSONEncoder().encode(md) {
            self.metadataString = String(data: mdData, encoding: .utf8)
        } else {
            self.metadataString = nil
        }
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        guard !name.isEmpty else { return false }
        
        if let pRid = parentRid, let currentRid = rid {
            guard pRid != currentRid else {
                return false
            }
        }
        return true
    }
    
    var hasUnsyncedChanges: Bool {
        if self.syncStatus != .synced {
            return true
        }
        return self.children.contains(where: { $0.hasUnsyncedChanges })
    }
    
    var optionalChildren: [DataMediaItem]? { children.isEmpty ? nil : children.sorted(by: { $0.name < $1.name}) }
}

// MARK: - Data Transfer Objects (DTOs)

struct DataMediaItemMetadata: Codable, Hashable {
    var mediaType: String?
    var author: String?
    var coverUrl: String?
}

struct DataMediaItemDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let parent_id: Int?
    let icon: String?
    let selectable: Bool
    let archived: Bool
    let untracked_consumptions: Int
    let metadata: DataMediaItemMetadata?
}

struct DataMediaItemPayload: Codable, InitializableWithModel {
    let name: String
    let parent_id: Int?
    let icon: String?
    let selectable: Bool
    let archived: Bool
    let untracked_consumptions: Int
    let metadata: DataMediaItemMetadata?
    
    typealias Model = DataMediaItem
    
    init?(from context: DataMediaItem) {
        guard context.isValid() else { return nil }
        
        self.name = context.name
        self.parent_id = context.parentRid
        self.icon = context.icon
        self.selectable = context.selectable
        self.archived = context.archived
        self.untracked_consumptions = context.untrackedConsumptions
        
        if let ms = context.metadataString, let mdData = ms.data(using: .utf8) {
            self.metadata = try? JSONDecoder().decode(DataMediaItemMetadata.self, from: mdData)
        } else {
            self.metadata = nil
        }
    }
}

struct DataMediaItemEditor: EditorProtocol {
    var name: String
    var parentRid: Int?
    var parent: DataMediaItem?
    var icon: String?
    var selectable: Bool = true
    var archived: Bool = false
    var cache: Bool = true
    var untrackedConsumptions: Int = 0
    var metadataString: String?
    
    typealias Model = DataMediaItem
    
    init(from context: DataMediaItem) {
        self.name = context.name
        self.parent = context.parent
        self.parentRid = context.parentRid
        self.icon = context.icon
        self.selectable = context.selectable
        self.archived = context.archived
        self.cache = context.cache
        self.untrackedConsumptions = context.untrackedConsumptions
        self.metadataString = context.metadataString
    }
    
    func apply(to context: DataMediaItem) {
        context.name = self.name
        context.parent = self.parent
        context.parentRid = self.parentRid ?? self.parent?.rid
        context.icon = self.icon
        context.selectable = self.selectable
        context.archived = self.archived
        context.cache = self.cache
        context.untrackedConsumptions = self.untrackedConsumptions
        context.metadataString = self.metadataString
        
        context.markAsModified()
    }
}

extension DataMediaItem: Equatable {
    static func == (lhs: DataMediaItem, rhs: DataMediaItem) -> Bool {
        lhs.rid == rhs.rid && lhs.id == rhs.id
    }
}

extension DataMediaItem {
    @discardableResult
    static func create(in context: ModelContext) -> DataMediaItem {
        let newItem = DataMediaItem()
        newItem.syncStatusRaw = SyncStatus.unsynced.rawValue
        context.insert(newItem)
        try? context.save()
        return newItem
    }
}
