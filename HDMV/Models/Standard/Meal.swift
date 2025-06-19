//
//  Meal.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.06.2025.
//

import Foundation
import SwiftData

@Model
final class Meal: Identifiable {
    @Attribute(.unique) var id: Int
    var date: String = Date().rawValue
    var timeStart: String
    var timeEnd: String?
    var content: String
    
    // This holds the foreign key ID
    var mealTypeId: Int
    
    @Transient var syncStatus: SyncStatus = .local
    // This establishes the actual relationship to MealType
    // SwiftData will automatically link this based on a matching attribute if set up correctly,
    // but for fetching, we'll manually link them.
    @Transient var mealType: MealType?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case timeStart = "time_start"
        case timeEnd = "time_end"
        case content
        case mealTypeId = "meal_id"
    }
    
    // Memberwise initializer
    init(id: Int, date: String, timeStart: String, timeEnd: String?, content: String, mealTypeId: Int, syncStatus: SyncStatus = .synced) {
        self.id = id
        self.date = date
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.content = content
        self.mealTypeId = mealTypeId
    }
    
    // Decodable initializer
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.date = try container.decode(String.self, forKey: .date)
        self.timeStart = try container.decode(String.self, forKey: .timeStart)
        self.timeEnd = try container.decodeIfPresent(String.self, forKey: .timeEnd)
        self.content = try container.decode(String.self, forKey: .content)
        self.mealTypeId = try container.decode(Int.self, forKey: .mealTypeId)
    }
    
    // Encodable function
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(timeStart, forKey: .timeStart)
        try container.encodeIfPresent(timeEnd, forKey: .timeEnd)
        try container.encode(content, forKey: .content)
        try container.encode(mealTypeId, forKey: .mealTypeId)
    }
}

struct MealDTO: Codable, Identifiable, Sendable {
    var id: Int?
    let date: String
    let timeStart: String
    let timeEnd: String?
    let content: String
    let mealTypeId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, date, content
        case timeStart = "time_start"
        case timeEnd = "time_end"
        case mealTypeId = "meal_id"
    }
}

func dtosToMealObjects(from dtos: [MealDTO]) -> [Meal] {
    return dtos.map { dto in
        Meal(
            id: dto.id ?? -1,
            date: dto.date,
            timeStart: dto.timeStart,
            timeEnd: dto.timeEnd,
            content: dto.content,
            mealTypeId: dto.mealTypeId,
        )
    }
}

/// Helper to convert a Meal model to a MealDTO.
func mealToDTO(_ meal: Meal) -> MealDTO {
    return MealDTO(
        id: meal.id,
        date: meal.date,
        timeStart: meal.timeStart,
        timeEnd: meal.timeEnd,
        content: meal.content,
        mealTypeId: meal.mealTypeId
    )
}
