//
//  VehicleType.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation
import SwiftData

@Model
final class VehicleType {
    @Attribute(.unique) var id: Int
    var slug: String
    var name: String
    var icon: String
    var cache: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case id, slug, name, icon, cache
    }
    
    init(id: Int, slug: String, name: String, icon: String) {
        self.id = id
        self.slug = slug
        self.name = name
        self.icon = icon
        self.cache = cache
    }
    
    init(fromDto dto: VehicleTypeDTO){
        self.id = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.icon = dto.icon
        self.cache = dto.cache
    }
    
    var label: String {
        return "\(self.icon) \(self.name)"
    }
    
}

struct VehicleTypeDTO: Codable, Identifiable, Sendable {
    let id: Int
    let slug: String
    let name: String
    let icon: String
    let cache: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, slug, name, icon, cache
    }
}

struct NewVehicleTypePayload: Encodable {
    var slug: String = ""
    var name: String = ""
    var icon: String = ""
}

