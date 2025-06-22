//
//  City.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation
import SwiftData

@Model
final class City {
    @Attribute(.unique) var id: Int
    var slug: String
    var name: String
    var rank: Int
    var country_id: Int
    var cache: Bool = true
    
    init(id: Int, slug: String, name: String, rank: Int, country_id: Int, cache: Bool = true) {
        self.id = id
        self.slug = slug
        self.name = name
        self.rank = rank
        self.country_id = country_id
        self.cache = cache
    }
}

struct CityDTO: Codable, Identifiable, Sendable {
    var id: Int?
    var slug: String
    var name: String
    var rank: Int
    var country_id: Int
    var cache: Bool
}

struct NewCityPayload: Encodable {
    var slug: String
    var name: String
    var rank: Int
    var country_id: Int
    var cache: Bool = true
}
