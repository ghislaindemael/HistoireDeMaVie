//
//  Vehicle.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//
import Foundation
import SwiftData

@Model
final class Vehicle: Identifiable, Hashable, Codable {
    @Attribute(.unique) var id: Int
    var name: String
    var favourite: Bool
    var type: Int
    var city_id: Int?
    
    @Transient var vehicleType: VehicleType?
    @Transient var city: City?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case favourite
        case type
        case city_id
    }
    
    init(id: Int, name: String, favourite: Bool, type: Int, city_id: Int? = nil) {
        self.id = id
        self.name = name
        self.favourite = favourite
        self.type = type
        self.city_id = city_id
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.favourite = try container.decode(Bool.self, forKey: .favourite)
        self.type = try container.decode(Int.self, forKey: .type)
        self.city_id = try container.decode(Int.self, forKey: .city_id)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(favourite, forKey: .favourite)
        try container.encode(type, forKey: .type)
        try container.encode(city_id, forKey: .city_id)
        
    }
}

struct VehicleDTO: Codable, Identifiable, Sendable {
    var id: Int?
    var name: String
    var favourite: Bool
    var type: Int
    var city_id: Int?

    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case favourite
        case type
        case city_id
    }
}

func dtosToVehicleObjects(from dtos: [VehicleDTO]) -> [Vehicle] {
    return dtos.map { dto in
        Vehicle(
            id: dto.id!,
            name: dto.name,
            favourite: dto.favourite,
            type: dto.type,
            city_id: dto.city_id
            
        )
    }
}

func vehicleToDTO(_ vehicle: Vehicle) -> VehicleDTO {
    return VehicleDTO(
        id: vehicle.id,
        name: vehicle.name,
        favourite: vehicle.favourite,
        type: vehicle.type,
        city_id: vehicle.city_id
    )
}
