import Foundation
import SwiftData

@Model
final class LifeEventType: Identifiable, Hashable, SyncableModel, EditableModel, CachableObject, TreeSelectable, CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    var name: String
    var slug: String
    
    var parentRid: Int?
    var parent: LifeEventType? {
        didSet {
            parentRid = parent?.rid
        }
    }
    
    @Relationship(deleteRule: .nullify, inverse: \LifeEventType.parent)
    var children: [LifeEventType] = []
    
    @Relationship(deleteRule: .cascade, inverse: \DataLogOptionMapping.lifeEventType)
    var optionMappings: [DataLogOptionMapping] = []
    
    var icon: String?
    var cache: Bool = true
    var archived: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    // Derived property
    var hasUnsyncedChanges: Bool {
        if self.syncStatus != .synced {
            return true
        }
        return self.children.contains(where: { $0.hasUnsyncedChanges })
    }
    var optionalChildren: [LifeEventType]? { children.isEmpty ? nil : children.sorted(by: { $0.name < $1.name}) }
    var cachedOptionalChildren: [LifeEventType]? {
        let cached = children.filter { $0.cache }
        return cached.isEmpty ? nil : cached.sorted(by: { $0.name < $1.name })
    }
    
    typealias Payload = LifeEventTypePayload
    typealias DTO = LifeEventTypeDTO
    typealias Editor = LifeEventTypeEditor
    
    init(
        rid: Int? = nil,
        name: String,
        slug: String,
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
    
    convenience init(fromDto dto: LifeEventTypeDTO) {
        self.init(
            rid: dto.id,
            name: dto.name,
            slug: dto.slug,
            parentRid: dto.parent_id,
            icon: dto.icon,
            cache: dto.cache ?? true,
            archived: dto.archived ?? false,
            syncStatus: .synced
        )
    }
    
    func update(fromDto dto: LifeEventTypeDTO) {
        self.name = dto.name
        self.slug = dto.slug
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.cache = dto.cache ?? true
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    var label: String {
        "\(icon ?? "ℹ️") \(name)"
    }
    
    func isValid() -> Bool {
        return !name.isEmpty && !slug.isEmpty
    }
}

// MARK: - DTO and Payload

struct LifeEventTypeDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String?
    let cache: Bool?
    let archived: Bool?
}

struct LifeEventTypePayload: Codable, InitializableWithModel {
    typealias Model = LifeEventType
    
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String?
    let cache: Bool
    let archived: Bool
    
    init?(from model: LifeEventType) {
        guard model.isValid() else { return nil }
        self.name = model.name
        self.slug = model.slug
        self.parent_id = model.parentRid
        self.icon = model.icon
        self.cache = model.cache
        self.archived = model.archived
    }
}

struct LifeEventTypeEditor: CachableModel, EditorProtocol {
    typealias Model = LifeEventType
    
    var name: String = ""
    var slug: String = ""
    var parentRid: Int?
    var parent: LifeEventType?
    var icon: String? = nil
    var cache: Bool = true
    var archived: Bool = false
    
    init() {}
    
    init(from model: LifeEventType) {
        self.name = model.name
        self.slug = model.slug
        self.parentRid = model.parentRid
        self.parent = model.parent
        self.icon = model.icon
        self.cache = model.cache
        self.archived = model.archived
    }
    
    func apply(to model: LifeEventType) {
        model.name = self.name
        model.slug = self.slug
        
        model.parent = self.parent
        model.parentRid = self.parent?.rid ?? self.parentRid
        
        model.icon = self.icon
        model.cache = self.cache
        model.archived = self.archived
    }
}
