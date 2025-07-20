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
    var time_start: Date
    var time_end: Date?
    var content: String?
    var mealTypeId: Int
    var syncStatus: SyncStatus = SyncStatus.local
    
    @Transient var mealType: MealType?
    
    enum CodingKeys: String, CodingKey {
        case id, time_start, time_end, content
        case mealTypeId = "type_id"
    }
    
    // Memberwise initializer
    init(id: Int, time_start: Date, time_end: Date?, content: String?, mealTypeId: Int = 0, syncStatus: SyncStatus = .local) {
        self.id = id
        self.time_start = time_start
        self.time_end = time_end
        self.content = content
        self.mealTypeId = mealTypeId
        self.syncStatus = syncStatus
    }
    
    init(fromDTO dto: MealDTO) {
        self.id = dto.id
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.content = dto.content
        self.mealTypeId = dto.mealTypeId
        self.syncStatus = SyncStatus.synced
    }
    
}

struct MealDTO: Codable, Identifiable, Sendable {
    var id: Int
    let time_start: Date
    let time_end: Date?
    let content: String?
    let mealTypeId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, time_start, time_end, content
        case mealTypeId = "type_id"
    }
    
    init(from meal: Meal){
        self.id = meal.id
        self.time_start = meal.time_start
        self.time_end = meal.time_end
        self.content = meal.content
        self.mealTypeId = meal.mealTypeId
    }
}

struct NewMealPayload: Encodable {
    var time_start: Date
    var time_end: Date?
    var content: String?
    var mealTypeId: Int
    
    init() {
        self.time_start = .now
        self.time_end = nil
        self.content = nil
        self.mealTypeId = -1
    }
    
    init(time_start: Date, time_end: Date? = nil,
         content: String?, mealTypeId: Int = 0) {
        self.time_start = time_start
        self.time_end = time_end
        self.content = content
        self.mealTypeId = mealTypeId
        
    }
    
    init(fromMeal meal: Meal){
        self.time_start = meal.time_start
        self.time_end = meal.time_end
        self.content = meal.content
        self.mealTypeId = meal.mealTypeId
    }
    
    enum CodingKeys: String, CodingKey {
        case time_start
        case time_end
        case content
        case mealTypeId = "type_id"
    }
}


func dtosToMealObjects(from dtos: [MealDTO]) -> [Meal] {
    return dtos.map { dto in
        Meal(
            id: dto.id,
            time_start: dto.time_start,
            time_end: dto.time_end,
            content: dto.content,
            mealTypeId: dto.mealTypeId,
            syncStatus: SyncStatus.synced
        )
    }
}
