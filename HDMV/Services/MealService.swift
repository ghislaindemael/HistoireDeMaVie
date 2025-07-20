//
//  MealService.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.06.2025.
//


//
//  MealService.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.06.2025.
//

import Foundation

class MealService {
    
    private let supabaseClient = SupabaseService.shared.client
    
    /// Fetches all standard meal types from the 'data_meals' table in Supabase.
    /// - Returns: An array of `MealType` objects.
    /// - Throws: An error if the network request or decoding fails.
    func fetchAllMealTypes() async throws -> [MealTypeDTO] {
        guard let supabaseClient = SupabaseService.shared.client else {
            return []
        }
        
        let response: [MealTypeDTO] = try await supabaseClient
            .from("data_meals")
            .select()
            .execute()
            .value
        
        return response
    }
    
    func fetchMeals(for date: Date) async throws -> [MealDTO] {
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        guard let supabaseClient = SupabaseService.shared.client else {
            return []
        }
        
        return try await supabaseClient
            .from("my_meals")
            .select()
            .gte("time_start", value: ISO8601DateFormatter().string(from: startOfDay))
            .lt("time_start", value: ISO8601DateFormatter().string(from: endOfDay))
            .order("time_start", ascending: true)
            .execute()
            .value
        
    }
    
    func insertMeal(_ newMeal: NewMealPayload) async throws -> MealDTO {

        guard let supabase = self.supabaseClient else {
            throw NSError(
                domain: "MealServiceError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Supabase client is not initialized."]
            )
        }
        
        let insertedMeals: [MealDTO] = try await supabase
            .from("my_meals")
            .insert(newMeal, returning: .representation)
            .select()
            .execute()
            .value
        
        
        guard let newMeal = insertedMeals.first else {
            throw NSError(domain: "MealServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode inserted meal after insertion."])
        }
        
        return newMeal
    }
    
    func updateMeal(mealDto dto: MealDTO) async throws -> Bool {
        guard let supabase = self.supabaseClient else {
            throw NSError(domain: "MealServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client is not initialized."])
        }
        
        let updatedMeals: [MealDTO] = try await supabase
            .from("my_meals")
            .update(dto)
            .eq("id", value: dto.id)
            .select()
            .execute()
            .value
                
        return !updatedMeals.isEmpty
    }


}
