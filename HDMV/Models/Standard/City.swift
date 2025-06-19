//
//  City.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation

struct City: Identifiable, Hashable, Codable {
    let id: Int
    let slug: String
    let name: String
    let countryID: Int
    let isMajor: Bool
    
    init(id: Int, slug: String, name: String, countryID: Int, isMajor: Bool) {
        self.id = id
        self.slug = slug
        self.name = name
        self.countryID = countryID
        self.isMajor = isMajor
    }
}
