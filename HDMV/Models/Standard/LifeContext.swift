//
//  LifeContext.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation
import SwiftData

@Model
final class LifeContext: Identifiable, Hashable, SyncableModel, EditableModel, CachableObject {
    
    var rid: Int?
    var name: String
    
    var parentRid: Int?
    var parent: LifeContext? {
        didSet {
            parentRid = parent?.rid
        }
    }
    
    @Relationship(deleteRule: .nullify, inverse: \LifeContext.parent)
    var children: [LifeContext] = []
    
    var selectable: Bool = true
    var archived: Bool = false
    var cache: Bool = true
    var icon: String?
    var timeStart: Date?
    var timeEnd: Date?
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = LifeContextPayload
    typealias DTO = LifeContextDTO
    typealias Editor = LifeContextEditor
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        parentRid: Int? = nil,
        icon: String? = nil,
        selectable: Bool = true,
        archived: Bool = false,
        timeStart: Date? = nil,
        timeEnd: Date? = nil,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.parentRid = parentRid
        self.icon = icon
        self.selectable = selectable
        self.archived = archived
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: LifeContextDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.selectable = dto.selectable
        self.archived = dto.archived
        self.timeStart = dto.start_date
        self.timeEnd = dto.end_date
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: LifeContextDTO) {
        self.name = dto.name
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.selectable = dto.selectable
        self.archived = dto.archived
        self.timeStart = dto.start_date
        self.timeEnd = dto.end_date
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
    
    var optionalChildren: [LifeContext]? { children.isEmpty ? nil : children.sorted(by: { $0.name < $1.name}) }
}

// MARK: - Data Transfer Objects (DTOs)

struct LifeContextDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let parent_id: Int?
    let icon: String?
    let selectable: Bool
    let archived: Bool
    let start_date: Date?
    let end_date: Date?
}

struct LifeContextPayload: Codable, InitializableWithModel {
    let name: String
    let parent_id: Int?
    let icon: String?
    let selectable: Bool
    let archived: Bool
    let start_date: Date?
    let end_date: Date?
    
    typealias Model = LifeContext
    
    init?(from context: LifeContext) {
        guard context.isValid() else { return nil }
        
        self.name = context.name
        self.parent_id = context.parentRid
        self.icon = context.icon
        self.selectable = context.selectable
        self.archived = context.archived
        self.start_date = context.timeStart
        self.end_date = context.timeEnd
    }
}

struct LifeContextEditor: EditorProtocol {
    var name: String
    var parentRid: Int?
    var parent: LifeContext? {
        didSet {
            parentRid = parent?.rid
        }
    }
    var icon: String?
    var selectable: Bool = true
    var archived: Bool = false
    var cache: Bool = true
    var timeStart: Date?
    var timeEnd: Date?
    
    typealias Model = LifeContext
    
    init(from context: LifeContext) {
        self.name = context.name
        self.parent = context.parent
        self.parentRid = context.parentRid
        self.icon = context.icon
        self.selectable = context.selectable
        self.archived = context.archived
        self.cache = context.cache
        self.timeStart = context.timeStart
        self.timeEnd = context.timeEnd
    }
    
    func apply(to context: LifeContext) {
        context.name = self.name
        context.parent = self.parent
        context.parentRid = self.parentRid
        context.icon = self.icon
        context.selectable = self.selectable
        context.archived = self.archived
        context.cache = self.cache
        context.timeStart = self.timeStart
        context.timeEnd = self.timeEnd
        
        context.markAsModified()
    }
}

extension LifeContext: Equatable {
    static func == (lhs: LifeContext, rhs: LifeContext) -> Bool {
        lhs.rid == rhs.rid && lhs.id == rhs.id
    }
}

extension LifeContext {
    @discardableResult
    static func create(in context: ModelContext) -> LifeContext {
        let newContext = LifeContext()
        newContext.syncStatusRaw = SyncStatus.unsynced.rawValue
        context.insert(newContext)
        try? context.save()
        return newContext
    }
}
