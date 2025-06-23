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
    
    init(id: Int, name: String, city_id: Int, cache: Bool = true) {
        self.id = id
        self.name = name
        self.city_id = city_id
        self.cache = cache
    }
}


// MARK: - DTOs for Network
struct PlaceDTO: Codable, Identifiable, Sendable {
    var id: Int?
    var name: String
    var city_id: Int
    var cache: Bool
}

struct NewPlacePayload: Encodable {
    var name: String
    var city_id: Int
    var cache: Bool
}
