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
    
    @Attribute(.unique) var id: Int
    var name: String
    var slug: String
    var parent_id: Int?
    var icon: String
    var type: ActivityType?
    var allowedCapabilities: [ActivityCapability] = []
    var requiredCapabilities: [ActivityCapability] = []
    var selectable: Bool = true
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue

    @Transient var children: [Activity] = []
    

    init(
        id: Int,
        name: String,
        slug: String,
        parent_id: Int? = nil,
        icon: String,
        type: ActivityType? = nil,
        allowedCapabilities: [ActivityCapability] = [],
        requiredCapabilities: [ActivityCapability] = [],
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
        self.id = dto.id
        self.name = dto.name
        self.slug = dto.slug
        self.parent_id = dto.parent_id
        self.icon = dto.icon
        self.type = dto.type
        self.selectable = dto.selectable
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = SyncStatus.synced
        
        self.allowedCapabilities = dto.allowed_capabilities.compactMap { ActivityCapability(rawValue: $0) }
        self.requiredCapabilities = dto.required_capabilities.compactMap { ActivityCapability(rawValue: $0) }
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
        self.selectable = dto.selectable
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
        
        self.allowedCapabilities = dto.allowed_capabilities.compactMap { ActivityCapability(rawValue: $0) }
        self.requiredCapabilities = dto.required_capabilities.compactMap { ActivityCapability(rawValue: $0) }
        
    }
    
    /// Creates a data transfer object (payload) from the model instance.
    func toPayload() -> ActivityPayload {
        return ActivityPayload(
            name: self.name,
            slug: self.slug,
            parent_id: self.parent_id,
            icon: self.icon,
            type: self.type,
            allowed_capabilities: self.allowedCapabilities.map { $0.rawValue },
            required_capabilities: self.requiredCapabilities.map { $0.rawValue },
            selectable: self.selectable,
            cache: self.cache,
            archived: self.archived
        )
    }
    
    func isValid() -> Bool {
        return true
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
    let allowed_capabilities: [String]
    let required_capabilities: [String]
    let selectable: Bool
    let cache: Bool
    let archived: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, name, slug, parent_id, icon, type, selectable, cache, archived
        case allowed_capabilities, required_capabilities
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        parent_id = try container.decodeIfPresent(Int.self, forKey: .parent_id)
        icon = try container.decode(String.self, forKey: .icon)
        type = try container.decodeIfPresent(ActivityType.self, forKey: .type)
        selectable = try container.decode(Bool.self, forKey: .selectable)
        cache = try container.decode(Bool.self, forKey: .cache)
        archived = try container.decode(Bool.self, forKey: .archived)
        
        allowed_capabilities = try container.decodeIfPresent([String].self, forKey: .allowed_capabilities) ?? []
        required_capabilities = try container.decodeIfPresent([String].self, forKey: .required_capabilities) ?? []
    }
    
}

/// A DTO for the payload required to create a new activity.
struct ActivityPayload: Codable {
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String
    let type: ActivityType?
    let allowed_capabilities: [String]
    let required_capabilities: [String]
    let selectable: Bool
    let cache: Bool
    let archived: Bool
}


