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
    var typeSlug: String
    var type: VehicleType {
        get { VehicleType(rawValue: typeSlug) ?? .car }
        set { typeSlug = newValue.rawValue }
    }
    var city_id: Int?
    var label: String = ""
    var cache: Bool = true
    
    @Transient var city: City?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case cache
        case typeSlug = "type"
        case city_id
    }
    
    init(id: Int, name: String, typeSlug: String , city_id: Int? = nil, label: String = "") {
        self.id = id
        self.name = name
        self.typeSlug = typeSlug
        self.city_id = city_id
        self.label = label
        self.cache = cache
    }
    
    init(id: Int, name: String, type: VehicleType, city_id: Int? = nil, label: String = "") {
        self.id = id
        self.name = name
        self.typeSlug = type.rawValue
        self.city_id = city_id
    }
    
    init(fromDto dto: VehicleDTO) {
        self.id = dto.id
        self.name = dto.name
        self.typeSlug = dto.typeSlug
        self.city_id = dto.city_id
        self.cache = dto.cache
    }
}

struct VehicleDTO: Codable, Identifiable, Sendable {
    var id: Int
    var name: String
    var typeSlug: String
    var city_id: Int?
    var cache: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, city_id, cache
        case typeSlug = "type"
    }
}

struct NewVehiclePayload: Encodable {
    var name: String = ""
    var type: VehicleType = .car
    var city_id: Int? = nil
}

