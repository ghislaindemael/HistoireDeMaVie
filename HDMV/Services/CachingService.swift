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
    @Published var cachedVehicleTypes: [VehicleType] = []
    
    private let modelContainer: ModelContainer
    private let mealService = MealService()
    private let vehicleService = VehicleService()
    
    private var initialLoadingTask: Task<Void, Never>?
    
    private init() {
        self.modelContainer = HDMVApp.sharedModelContainer
        
        self.initialLoadingTask = Task {
            await self.loadLocalMealTypes()
            await self.loadLocalVehicleTypes()
        }
    }
    
    func ensureCacheIsLoaded() async {
        await initialLoadingTask?.value
    }
    
    /// Fetches fresh meal types from the `MealService`, deletes all existing `MealType`
    /// entries from the local SwiftData store, and saves the new data.
    func cacheMealTypes() async throws {
        // 1. Fetch fresh data using the MealService
        let mealTypeDTOS = try await mealService.fetchAllMealTypes()
        let mealTypes = dtosToMealTypeObjects(from: mealTypeDTOS)
        
        // 2. Clear existing MealType data from the local store
        try modelContainer.mainContext.delete(model: MealType.self)
        
        // 3. Insert the new data
        for mealType in mealTypes {
            modelContainer.mainContext.insert(mealType)
        }
        
        // 4. Save the changes
        try modelContainer.mainContext.save()
        
        // 5. Update the published property
        await self.loadLocalMealTypes()
    }
    
    /// Loads all `MealType` objects from the local SwiftData store into the `cachedMealTypes` property.
    func loadLocalMealTypes() async {
        let descriptor = FetchDescriptor<MealType>(sortBy: [SortDescriptor(\.id)])
        if let mealTypes = try? modelContainer.mainContext.fetch(descriptor) {
            self.cachedMealTypes = mealTypes
        }
    }
    
    func cacheVehiclesTypes() async throws {
        
        let vehicleTypeDTOS = try await vehicleService.fetchVehicleTypes()
        let vehicleTypes = dtosToVehicleTypeObjects(from: vehicleTypeDTOS)
        
        try modelContainer.mainContext.delete(model: VehicleType.self)
        
        for vehicleType in vehicleTypes {
            modelContainer.mainContext.insert(vehicleType)
        }
        
        try modelContainer.mainContext.save()
        await self.loadLocalVehicleTypes()
        
    }
    
    func loadLocalVehicleTypes() async {
        let descriptor = FetchDescriptor<VehicleType>(sortBy: [SortDescriptor(\.id)])
        if let vehicleTypes = try? modelContainer.mainContext.fetch(descriptor) {
            self.cachedVehicleTypes = vehicleTypes
        }
    }
}
