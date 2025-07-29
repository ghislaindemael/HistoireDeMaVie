//
//  Place.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation
import SwiftData

// MARK: - SwiftData Model
@Model
final class Place {
    @Attribute(.unique) var id: Int
    var name: String
    var city_id: Int
    var localName: String = ""
    var cache: Bool = true
    var archived: Bool = false
    
    init(id: Int, name: String, city_id: Int, cache: Bool = true, archived: Bool = false) {
        self.id = id
        self.name = name
        self.city_id = city_id
        self.cache = cache
        self.archived = archived
    }
    
    init(fromDto dto: PlaceDTO) {
        self.id = dto.id
        self.name = dto.name
        self.city_id = dto.city_id
        self.cache = dto.cache
        self.archived = dto.archived
    }
}


// MARK: - DTOs for Network
struct PlaceDTO: Codable, Identifiable, Sendable {
    var id: Int
    var name: String
    var city_id: Int
    var cache: Bool
    var archived: Bool
}

struct NewPlacePayload: Encodable {
    var name: String
    var city_id: Int
}
