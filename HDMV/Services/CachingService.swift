//
//  CachingService.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.06.2025.
//

import Foundation
import SwiftData

@MainActor
class CachingService: ObservableObject {
    
    static let shared = CachingService()
    
    @Published var cachedMealTypes: [MealType] = []
    
    private let modelContainer: ModelContainer
    private let mealService = MealService() // Use the new MealService
    
    private var initialLoadingTask: Task<Void, Never>?
    
    private init() {
        // Use the single, persistent container you defined in your App struct.
        self.modelContainer = HDMVApp.sharedModelContainer
        
        // Now, this function will load from the CORRECT database on app launch.
        self.initialLoadingTask = Task {
            await self.loadMealTypesFromLocalStore()
        }
    }
    
    func ensureCacheIsLoaded() async {
        // Await the value of the task. If the task is already complete,
        // this returns instantly. If it's not, it waits for it to finish.
        await initialLoadingTask?.value
    }
    
    /// Fetches fresh meal types from the `MealService`, deletes all existing `MealType`
    /// entries from the local SwiftData store, and saves the new data.
    func recacheMealTypes() async throws {
        // 1. Fetch fresh data using the MealService
        let mealTypeDTOS = try await mealService.fetchAllMealTypes()
        let mealTypes = convertToMealTypeEntities(from: mealTypeDTOS)
        
        // 2. Clear existing MealType data from the local store
        try modelContainer.mainContext.delete(model: MealType.self)
        
        // 3. Insert the new data
        for mealType in mealTypes {
            modelContainer.mainContext.insert(mealType)
        }
        
        // 4. Save the changes
        try modelContainer.mainContext.save()
        
        // 5. Update the published property
        await self.loadMealTypesFromLocalStore()
    }
    
    /// Loads all `MealType` objects from the local SwiftData store into the `cachedMealTypes` property.
    func loadMealTypesFromLocalStore() async {
        let descriptor = FetchDescriptor<MealType>(sortBy: [SortDescriptor(\.id)])
        if let mealTypes = try? modelContainer.mainContext.fetch(descriptor) {
            self.cachedMealTypes = mealTypes
        }
    }
}
