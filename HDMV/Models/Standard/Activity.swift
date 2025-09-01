//
//  Activity.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData

@Model
final class Activity: Identifiable, Hashable, SyncableModel {
    @Attribute(.unique) var id: Int
    var name: String
    var slug: String
    var parent_id: Int?
    var icon: String
    var type: ActivityType?
    var permissions: [String] = []
    var selectable: Bool = true
    var cache: Bool = true
    var archived: Bool = false
    var syncStatus: SyncStatus = SyncStatus.undef

    @Transient var children: [Activity] = []
    
    var canCreateTripLegs: Bool {
        permissions.contains("trips")
    }
    
    var canCreateInteractions: Bool {
        permissions.contains("people")
    }
    
    init(
        id: Int,
        name: String,
        slug: String,
        parent_id: Int? = nil,
        icon: String,
        type: ActivityType? = nil,
        permissions: [String] = [],
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .undef
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.parent_id = parent_id
        self.icon = icon
        self.type = type
        self.permissions = permissions
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, cache, archived, parent_id, icon, type, permissions, selectable
    }
    
    init(fromDto dto: ActivityDTO) {
        self.id = dto.id
        self.name = dto.name
        self.slug = dto.slug
        self.parent_id = dto.parent_id
        self.icon = dto.icon
        self.type = dto.type
        self.permissions = dto.permissions
        self.selectable = dto.selectable
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = SyncStatus.synced
    }
    
    // MARK: - Tree Building Logic
    
    /// Takes a flat array of activities and organizes them into a tree structure.
    /// - Parameter activities: A flat array fetched from the server or cache.
    /// - Returns: An array of the root-level activities, each with its children populated.
    static func buildTree(from activities: [Activity]) -> [Activity] {
        var lookup = [Int: Activity]()
        for activity in activities {
            lookup[activity.id] = activity
            activity.children = []
        }
        
        var rootNodes: [Activity] = []
        
        for activity in activities {
            if let parent_id = activity.parent_id, let parent = lookup[parent_id] {
                parent.children.append(activity)
            } else {
                rootNodes.append(activity)
            }
        }
        
        for activity in activities {
            activity.children.sort { $0.name < $1.name }
        }
        
        return rootNodes.sorted { $0.name < $1.name }
    }
    
    func flattened() -> [Activity] {
        var result = [self]
        
        for child in children {
            result.append(contentsOf: child.flattened())
        }
        
        return result
    }
    
    var optionalChildren: [Activity]? {
        return self.children.isEmpty ? nil : self.children
    }
    
    func update(fromDto dto: ActivityDTO) {
        self.name = dto.name
        self.slug = dto.slug
        self.parent_id = dto.parent_id
        self.icon = dto.icon
        self.type = dto.type
        self.permissions = dto.permissions
        self.selectable = dto.selectable
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    /// Creates a data transfer object (payload) from the model instance.
    func toPayload() -> ActivityPayload {
        return ActivityPayload(
            name: self.name,
            slug: self.slug,
            parent_id: self.parent_id,
            icon: self.icon,
            type: self.type,
            permissions: self.permissions,
            selectable: self.selectable,
            cache: self.cache,
            archived: self.archived
        )
    }
    
}

// MARK: - Data Transfer Objects (DTOs)

/// A DTO representing the structure of an activity from the JSON API.
struct ActivityDTO: Codable {
    let id: Int
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String
    let type: ActivityType?
    let permissions: [String]
    let selectable: Bool
    let cache: Bool
    let archived: Bool
}

/// A DTO for the payload required to create a new activity.
struct ActivityPayload: Codable {
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String
    let type: ActivityType?
    let permissions: [String]
    let selectable: Bool
    let cache: Bool
    let archived: Bool
}
