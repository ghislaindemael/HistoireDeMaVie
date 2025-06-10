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
    
    // Use the shared Supabase client
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
        let dateString = ISO8601DateFormatter.justDate.string(from: date)
        
        guard let supabaseClient = SupabaseService.shared.client else {
            return []
        }
        
        let response: [MealDTO] = try await supabaseClient
            .from("my_meals")
            .select()
            .eq("date", value: dateString)
            .execute()
            .value
        
        return response
    }
    
    func insertMeal(_ mealDto: MealDTO) async throws -> MealDTO {

        guard let supabase = self.supabaseClient else {
            throw NSError(
                domain: "MealServiceError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Supabase client is not initialized."]
            )
        }
        
        let insertedMeals: [MealDTO] = try await supabase
            .from("my_meals")
            .insert(mealDto, returning: .representation)
            .select()
            .execute()
            .value
        
        guard let newMeal = insertedMeals.first else {
            throw NSError(domain: "MealServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode inserted meal after insertion."])
        }
        
        return newMeal
    }
    
    func updateMeal(_ mealDto: MealDTO) async throws {
        guard let supabase = self.supabaseClient else {
            throw NSError(domain: "MealServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client is not initialized."])
        }
        
        // Update the row in the 'my_meals' table where the 'id' matches.
        try await supabase
            .from("my_meals")
            .update(mealDto)
            .eq("id", value: mealDto.id)
            .execute()
    }


}

extension ISO8601DateFormatter {
    static let justDate: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
