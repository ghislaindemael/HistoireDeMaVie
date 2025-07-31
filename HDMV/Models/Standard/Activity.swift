//
//  Activity.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData

@Model
final class Activity: Identifiable, Hashable {
    @Attribute(.unique) var id: Int
    var name: String
    var slug: String
    var parent_id: Int?
    var icon: String
    var cache: Bool
    var archived: Bool
    
    // Used to build the tree structure in memory after fetching.
    @Transient var children: [Activity] = []
    
    init(id: Int, name: String, slug: String, parent_id: Int? = nil, icon: String, cache: Bool = true, archived: Bool = false) {
        self.id = id
        self.name = name
        self.slug = slug
        self.parent_id = parent_id
        self.icon = icon
        self.cache = cache
        self.archived = archived
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, cache, archived, parent_id, icon
    }
    
    init(fromDto dto: ActivityDTO) {
        self.id = dto.id
        self.name = dto.name
        self.slug = dto.slug
        self.parent_id = dto.parent_id
        self.icon = dto.icon
        self.cache = dto.cache
        self.archived = dto.archived
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
    
    
}

// MARK: - Data Transfer Objects (DTOs)

/// A DTO representing the structure of an activity from the JSON API.
struct ActivityDTO: Codable {
    let id: Int
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String
    let cache: Bool
    let archived: Bool
}

/// A DTO for the payload required to create a new activity.
struct NewActivityPayload: Codable {
    let name: String
    let slug: String
    let parent_id: Int?
    let icon: String
}
