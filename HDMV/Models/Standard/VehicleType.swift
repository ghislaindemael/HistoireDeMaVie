//
//  VehicleType.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation
import SwiftData

@Model
final class VehicleType: Identifiable, Codable {
    @Attribute(.unique) var id: Int
    var slug: String
    var name: String
    var icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case icon
    }
    
    init(id: Int, slug: String, name: String, icon: String?) {
        self.id = id
        self.slug = slug
        self.name = name
        self.icon = icon
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.name = try container.decode(String.self, forKey: .name)
        self.icon = try container.decode(String.self, forKey: .icon)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(slug, forKey: .slug)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        
    }
    
}

struct VehicleTypeDTO: Codable, Identifiable, Sendable {
    let id: Int
    let slug: String
    let name: String
    let icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case icon
    }
}

func dtosToVehicleTypeObjects(from dtos: [VehicleTypeDTO]) -> [VehicleType] {
    return dtos.map { dto in
        VehicleType(
            id: dto.id,
            slug: dto.slug,
            name: dto.name,
            icon: dto.icon
        )
    }
}

/// Helper to convert a VehicleType model to a VehicleTypeDTO.
func vehicleTypeToDTO(_ vehicleType: VehicleType) -> VehicleTypeDTO {
    return VehicleTypeDTO(
        id: vehicleType.id,
        slug: vehicleType.slug,
        name: vehicleType.slug,
        icon: vehicleType.icon
    )
}
