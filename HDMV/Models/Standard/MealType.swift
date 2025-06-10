//
//  MealType.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.06.2025.
//


//
//  MealType.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.06.2025.
//

import Foundation
import SwiftData

@Model
final class MealType: Codable, Identifiable {
    @Attribute(.unique) var id: Int
    var slug: String
    var name: String
    var isMain: Bool
    var stdTime: String

    // Custom CodingKeys to map snake_case from Supabase to camelCase
    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case isMain = "is_main"
        case stdTime = "std_time"
    }
    
    // Memberwise initializer for creating instances
    init(id: Int, slug: String, name: String, isMain: Bool, stdTime: String) {
        self.id = id
        self.slug = slug
        self.name = name
        self.isMain = isMain
        self.stdTime = stdTime
    }

    // Decodable initializer
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.name = try container.decode(String.self, forKey: .name)
        self.isMain = try container.decode(Bool.self, forKey: .isMain)
        self.stdTime = try container.decode(String.self, forKey: .stdTime)
    }
    
    // Encodable function
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(slug, forKey: .slug)
        try container.encode(name, forKey: .name)
        try container.encode(isMain, forKey: .isMain)
        try container.encode(stdTime, forKey: .stdTime)
    }
}

struct MealTypeDTO: Codable, Identifiable, Sendable {
    let id: Int
    let slug: String
    let name: String
    let isMain: Bool
    let stdTime: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case isMain = "is_main"
        case stdTime = "std_time"
    }
}

func convertToMealTypeEntities(from dtos: [MealTypeDTO]) -> [MealType] {
    return dtos.map { dto in
        MealType(
            id: dto.id,
            slug: dto.slug,
            name: dto.name,
            isMain: dto.isMain,
            stdTime: dto.stdTime
        )
    }
}
