//
//  Activity.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Activity: Identifiable, Hashable, SyncableModel {
    
    typealias Payload = ActivityPayload
    
    var rid: Int?
    var name: String?
    var slug: String?
    var parentRid: Int?
    var parent: Activity? {
        didSet {
            parentRid = parent?.rid
        }
    }
    @Relationship(deleteRule: .nullify, inverse: \Activity.parent)
    var children: [Activity]? = []
    var icon: String?
    var allowedCapabilities: [ActivityCapability] = []
    var requiredCapabilities: [ActivityCapability] = []
    var selectable: Bool = true
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    init(
        rid: Int? = nil,
        name: String? = nil,
        slug: String? = nil,
        parentRid: Int? = nil,
        icon: String? = nil,
        allowedCapabilities: [ActivityCapability] = [],
        requiredCapabilities: [ActivityCapability] = [],
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .undef
    ) {
        self.rid = rid
        self.name = name
        self.slug = slug
        self.parentRid = parentRid
        self.icon = icon
        self.allowedCapabilities = allowedCapabilities
        self.requiredCapabilities = requiredCapabilities
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, cache, archived, parent_id, icon, type, selectable
        case allowedCapabilities = "allowed_capabilities"
        case requiredCapabilities = "required_capabilities"
    }
    
    init(fromDto dto: ActivityDTO) {
        self.rid = dto.id
        self.name = dto.name
        self.slug = dto.slug
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.selectable = dto.selectable
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = SyncStatus.synced
        
        self.allowedCapabilities = dto.allowed_capabilities?.compactMap { ActivityCapability(rawValue: $0) } ?? []
        self.requiredCapabilities = dto.required_capabilities?.compactMap { ActivityCapability(rawValue: $0) } ?? []
    }
    
    // MARK: - Activity Tree
    
    static func fetchActivityTree(from context: ModelContext) -> [Activity] {
        let predicate = #Predicate<Activity> { $0.parent == nil }
        let sortDescriptor = SortDescriptor(\Activity.name)
        let descriptor = FetchDescriptor<Activity>(predicate: predicate, sortBy: [sortDescriptor])
        return (try? context.fetch(descriptor)) ?? []
    }

    
    func update(fromDto dto: ActivityDTO) {
        self.name = dto.name
        self.slug = dto.slug
        self.parentRid = dto.parent_id
        self.icon = dto.icon
        self.selectable = dto.selectable
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
        
        self.allowedCapabilities = dto.allowed_capabilities?.compactMap { ActivityCapability(rawValue: $0) } ?? []
        self.requiredCapabilities = dto.required_capabilities?.compactMap { ActivityCapability(rawValue: $0) } ?? []
        
    }
        
    func isValid() -> Bool {
        return name != nil && slug != nil
    }
    
    func canLogDetails() -> Bool {
        return allowedCapabilities.count >= 1
    }
    
    var hasUnsyncedChanges: Bool {
        if self.syncStatus != .synced {
            return true
        }
        return self.children?.contains(where: { $0.hasUnsyncedChanges }) ?? false
    }
    
}

// MARK: - Data Transfer Objects (DTOs)

struct ActivityDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String
    let allowed_capabilities: [String]?
    let required_capabilities: [String]?
    let selectable: Bool
    let cache: Bool
    let archived: Bool
    
}

struct ActivityPayload: Codable, InitializableWithModel {
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String?
    let allowed_capabilities: [String]
    let required_capabilities: [String]
    let selectable: Bool
    let cache: Bool
    let archived: Bool
    
    typealias Model = Activity
    
    init?(from activity: Activity) {
        guard activity.isValid(),
              let name = activity.name,
              let slug = activity.slug
        else { return nil }
        
        self.name = name
        self.slug = slug
        self.parent_id = activity.parentRid
        self.icon = activity.icon
        self.allowed_capabilities = activity.allowedCapabilities.map { $0.rawValue }
        self.required_capabilities = activity.requiredCapabilities.map { $0.rawValue }
        self.selectable = activity.selectable
        self.cache = activity.cache
        self.archived = activity.archived
    }
}


struct ActivityEditor: CachableModel {
    var name: String?
    var slug: String?
    var parentRid: Int?
    var parent: Activity?
    var icon: String?
    var allowedCapabilities: [ActivityCapability] = []
    var requiredCapabilities: [ActivityCapability] = []
    var selectable: Bool = true
    var cache: Bool = true
    var archived: Bool = false
    
    init(from activity: Activity) {
        self.name = activity.name
        self.slug = activity.slug
        self.parentRid = activity.rid
        self.parent = activity.parent
        self.icon = activity.icon
        self.allowedCapabilities = activity.allowedCapabilities
        self.requiredCapabilities = activity.requiredCapabilities
        self.selectable = activity.selectable
        self.cache = activity.cache
        self.archived = activity.archived
    }
    
    func apply(to activity: Activity) {
        activity.name = self.name
        activity.slug = self.slug
        activity.parentRid = self.parentRid
        activity.parent = self.parent
        activity.icon = self.icon
        activity.allowedCapabilities = self.allowedCapabilities
        activity.requiredCapabilities = self.requiredCapabilities
        activity.selectable = self.selectable
        activity.cache = self.cache
        activity.archived = self.archived
    }
}


extension Activity: Equatable {
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }
}
