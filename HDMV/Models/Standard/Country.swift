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
    
    init(id: Int, slug: String, name: String) {
        self.id = id
        self.slug = slug
        self.name = name
    }
}

struct CountryDTO: Codable, Identifiable, Sendable {
    var id: Int
    var slug: String
    var name: String
}
