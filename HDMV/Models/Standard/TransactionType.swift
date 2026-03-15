//
//  TransactionType.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TransactionType: Identifiable, Hashable, SyncableModel, EditableModel, CachableObject {
    
    var rid: Int?
    var name: String
    var slug: String
    var parentRid: Int?
    var parent: TransactionType? {
        didSet {
            parentRid = parent?.rid
        }
    }
    @Relationship(deleteRule: .nullify, inverse: \TransactionType.parent)
    var children: [TransactionType] = []
    var icon: String?
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = TransactionTypePayload
    typealias DTO = TransactionTypeDTO
    typealias Editor = TransactionTypeEditor
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        slug: String = "unset",
        parentRid: Int? = nil,
        icon: String? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.slug = slug
        self.parentRid = parentRid
        self.icon = icon
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, cache, archived, parent_id, icon, type
    }
    
    convenience init(fromDto dto: TransactionTypeDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.slug = dto.slug
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.archived = dto.archived
        self.syncStatus = SyncStatus.synced
    }
    
    // MARK: - Activity Tree
    
    static func fetchTransactionTypeTree(from context: ModelContext) -> [TransactionType] {
        let predicate = #Predicate<TransactionType> { $0.parent == nil }
        let sortDescriptor = SortDescriptor(\TransactionType.name)
        let descriptor = FetchDescriptor<TransactionType>(predicate: predicate, sortBy: [sortDescriptor])
        return (try? context.fetch(descriptor)) ?? []
    }

    
    func update(fromDto dto: TransactionTypeDTO) {
        self.name = dto.name
        self.slug = dto.slug
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.archived = dto.archived
        self.syncStatus = .synced
        
    }
        
    func isValid() -> Bool {
        guard slug.isNotUnset() && name.isNotUnset() else { return false }
        
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
    
    var optionalChildren: [TransactionType]? { children.isEmpty ? nil : children.sorted(by: { $0.name < $1.name}) }
    
    var cachedOptionalChildren: [TransactionType]? {
        let cached = children.filter { $0.cache == true }
        return cached.isEmpty ? nil : cached.sorted(by: { $0.name < $1.name })
    }

    
}

// MARK: - Data Transfer Objects (DTOs)

struct TransactionTypeDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String?
    let archived: Bool
    
}

struct TransactionTypePayload: Codable, InitializableWithModel {
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String?
    let archived: Bool
    
    typealias Model = TransactionType
    
    init?(from type: TransactionType) {
        guard type.isValid() else { return nil }
        
        self.name = type.name
        self.slug = type.slug
        self.parent_id = type.parentRid
        self.icon = type.icon
        self.archived = type.archived
    }
}


struct TransactionTypeEditor: CachableModel, EditorProtocol {
    var name: String
    var slug: String
    var parentRid: Int?
    var parent: TransactionType?
    var icon: String?
    var cache: Bool = true
    var archived: Bool = false
    
    typealias Model = TransactionType
    
    init(from type: TransactionType) {
        self.name = type.name
        self.slug = type.slug
        self.parent = type.parent
        self.parentRid = type.parentRid
        self.icon = type.icon
        self.cache = type.cache
        self.archived = type.archived
    }
    
    func apply(to type: TransactionType) {
        type.name = self.name
        type.slug = self.slug
        type.parent = self.parent
        type.parentRid = self.parentRid ?? self.parent?.rid
        type.icon = self.icon
        type.cache = self.cache
        type.archived = self.archived
    }
}


extension TransactionType: Equatable {
    static func == (lhs: TransactionType, rhs: TransactionType) -> Bool {
        lhs.id == rhs.id
    }
}
