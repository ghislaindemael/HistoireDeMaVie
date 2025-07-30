//
//  Country.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import Foundation
import SwiftData

@Model
final class Country {
    @Attribute(.unique) var id: Int
    var slug: String
    var name: String
    var cache: Bool = true
    var archived: Bool = false
    
    init(id: Int, slug: String, name: String, cache: Bool = true, archived: Bool = false) {
        self.id = id
        self.slug = slug
        self.name = name
        self.cache = cache
        self.archived = archived
    }
    
    init(fromDto dto: CountryDTO){
        self.id = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.cache = dto.cache
        self.archived = dto.archived
    }
}

struct CountryDTO: Codable, Identifiable, Sendable {
    var id: Int
    var slug: String
    var name: String
    var cache: Bool = true
    var archived: Bool = false
}

struct NewCountryPayload: Encodable {
    var slug: String = ""
    var name: String = ""
}
