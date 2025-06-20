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
    
    init(id: Int, name: String, city_id: Int) {
        self.id = id
        self.name = name
        self.city_id = city_id
    }
}


// MARK: - DTOs for Network
struct PlaceDTO: Codable, Identifiable, Sendable {
    var id: Int?
    var name: String
    var city_id: Int
}

struct NewPlacePayload: Encodable {
    var name: String
    var city_id: Int
}