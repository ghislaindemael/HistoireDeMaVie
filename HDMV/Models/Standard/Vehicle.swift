//
//  Vehicle.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//
import Foundation
import SwiftData

@Model
final class Vehicle: Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var type: Int
    var city_id: Int?
    var label: String = ""
    var cache: Bool = true
    
    @Transient var city: City?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case cache
        case type
        case city_id
    }
    
    init(id: Int, name: String, type: Int, city_id: Int? = nil, cache: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.city_id = city_id
        self.cache = cache
    }
    
    init(fromDto dto: VehicleDTO) {
        self.id = dto.id
        self.name = dto.name
        self.type = dto.type
        self.city_id = dto.city_id
        self.cache = dto.cache
    }
}

struct VehicleDTO: Codable, Identifiable, Sendable {
    var id: Int
    var name: String
    var type: Int
    var city_id: Int?
    var cache: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, type, city_id, cache
    }
}

struct NewVehiclePayload: Encodable {
    var name: String = ""
    var type: Int = -1
    var city_id: Int? = nil
}

