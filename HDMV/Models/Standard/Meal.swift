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
    var syncStatus: SyncStatus = SyncStatus.local
    var mealTypeId: Int
    
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
    init(id: Int, date: String, timeStart: String, timeEnd: String?, content: String, mealTypeId: Int, syncStatus: SyncStatus = .local) {
        self.id = id
        self.date = date
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.content = content
        self.mealTypeId = mealTypeId
        self.syncStatus = syncStatus
    }
    
    init(fromDTO dto: MealDTO) {
        self.id = dto.id
        self.date = dto.date
        self.timeStart = dto.timeStart
        self.timeEnd = dto.timeEnd
        self.content = dto.content
        self.mealTypeId = dto.mealTypeId
        self.syncStatus = SyncStatus.synced
    }
    
}

struct MealDTO: Codable, Identifiable, Sendable {
    var id: Int
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
            id: dto.id,
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
