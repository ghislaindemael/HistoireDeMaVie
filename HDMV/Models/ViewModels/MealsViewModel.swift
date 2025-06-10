import Foundation
import SwiftData
import SwiftUI

@MainActor
class MealsViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAddingMeal = false
    
    private let mealService = MealService()
    // Get a direct reference to the main database context from our shared container
    private let modelContext: ModelContext
    
    private var cachedMealTypes: [MealType] {
        CachingService.shared.cachedMealTypes
    }
    
    init() {
        // Initialize the modelContext from the shared container
        self.modelContext = HDMVApp.sharedModelContainer.mainContext
    }
    
    // MARK: - Core Data Logic
    
    func fetchMealsForSelectedDate() async {
        isLoading = true
        errorMessage = nil
        
        await CachingService.shared.ensureCacheIsLoaded()
        
        do {
            // 1. Fetch remote meals from Supabase in the background
            async let remoteMealsTask = mealService.fetchMeals(for: selectedDate)
            
            // 2. Fetch locally saved, unsynced meals from SwiftData
            let localMeals = try fetchLocalUnsyncedMeals(for: selectedDate)
            
            // 3. Await the remote meals and convert them to Meal objects
            let remoteDTOs = try await remoteMealsTask
            let remoteMeals = dtoToMealObjects(from: remoteDTOs)
            
            // Add .synced status to all meals fetched from remote
            remoteMeals.forEach { $0.syncStatus = .synced }
            
            // 4. Merge the lists, preventing duplicates
            // Create a set of remote IDs for quick lookup
            let remoteMealIDs = Set(remoteMeals.map { $0.id })
            // Filter out any local meals that might have been synced since last launch
            let uniqueLocalMeals = localMeals.filter { !remoteMealIDs.contains($0.id) }
            
            // Combine and sort so new items appear at the top
            let allMeals = (remoteMeals + uniqueLocalMeals).sorted(by: { $0.timeStart > $1.timeStart })
            
            // 5. Link meal types to all meals
            let mealTypeMap = Dictionary(uniqueKeysWithValues: cachedMealTypes.map { ($0.id, $0) })
            for meal in allMeals {
                meal.mealType = mealTypeMap[meal.mealTypeId]
            }
            
            self.meals = allMeals
            
        } catch {
            self.errorMessage = "Error fetching meals: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Called from the AddMealSheet to create a new meal.
    func addMeal(_ meal: Meal) {
        // 1. SAVE LOCALLY FIRST to the SwiftData database
        modelContext.insert(meal)
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save meal locally: \(error.localizedDescription)"
            return
        }
        
        // 2. Add to the UI for instant feedback
        meal.mealType = cachedMealTypes.first { $0.id == meal.mealTypeId }
        meals.insert(meal, at: 0)
        
        // 3. Attempt to upload in the background
        Task {
            await uploadNewMeal(meal)
        }
    }
    
    /// Called from MealComponent when an existing meal is modified locally.
    func mealWasUpdated(_ meal: Meal) {
        // 1. Immediately save any local changes (like new content or end time)
        // to the persistent SwiftData store.
        do {
            try modelContext.save()
        } catch {
            print("Could not save context after local update: \(error)")
        }
        
        // 2. If the meal already exists on the server, start the sync process.
        if meal.id > 0 {
            guard let index = meals.firstIndex(where: { $0.id == meal.id }) else { return }
            
            objectWillChange.send()
            meals[index].syncStatus = .syncing
            Task {
                await self.syncExistingMealUpdate(mealId: meal.id)
            }
        }
    }
    
    
    /// Retries uploading a meal that previously failed.
    func retryUpload(for meal: Meal) {
        guard let index = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        
        objectWillChange.send()
        meals[index].syncStatus = .local // Show the spinner again
        
        Task {
            if meal.id < 0 {
                // This is a new meal that needs to be INSERTED
                await uploadNewMeal(meal)
            } else {
                // This is an existing meal that needs to be UPDATED
                await syncExistingMealUpdate(mealId: meal.id)
            }
        }
    }
        
    private func uploadNewMeal(_ meal: Meal) async {
        var mealDto = mealToDTO(meal)
        mealDto.id = nil
        
        do {
            // This attempts to save the meal to Supabase...
            let insertedDto = try await mealService.insertMeal(mealDto)
                        
            // 1. SUCCESS: Delete the temporary local meal from the SwiftData store.
            modelContext.delete(meal)
            try modelContext.save()
            
            // 2. Update the UI list to reflect the change.
            objectWillChange.send()
            if let index = meals.firstIndex(where: { $0.id == meal.id }) {
                meals.remove(at: index)
                
                let finalMeal = dtoToMealObjects(from: [insertedDto]).first!
                finalMeal.syncStatus = .synced
                finalMeal.mealType = cachedMealTypes.first { $0.id == finalMeal.mealTypeId }
                meals.insert(finalMeal, at: 0)
            }
            
        } catch {
            // On failure, the meal is NOT deleted and remains in the local database
            // with a 'failed' status, ready for a retry.
            if let index = meals.firstIndex(where: { $0.id == meal.id }) {
                objectWillChange.send()
                meals[index].syncStatus = .failed
            }
            print("Failed to upload meal: \(error)")
        }
    }
    
    private func syncExistingMealUpdate(mealId: Int) async { // <-- Takes an ID
        // Find the "live" meal object from the array to ensure we have the latest state
        guard let mealForDto = meals.first(where: { $0.id == mealId }) else {
            return
        }
        
        let mealDto = mealToDTO(mealForDto)
        
        do {
            try await mealService.updateMeal(mealDto)
            // Find the object again by its ID and update its status
            if let index = meals.firstIndex(where: { $0.id == mealId }) {
                objectWillChange.send()
                meals[index].syncStatus = .synced
            }
        } catch {
            if let index = meals.firstIndex(where: { $0.id == mealId }) {
                objectWillChange.send()
                meals[index].syncStatus = .failed
            }
            print("Failed to update meal: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    /// Fetches meals from the local database that have not yet been synced.
    private func fetchLocalUnsyncedMeals(for date: Date) throws -> [Meal] {
        let dateString = ISO8601DateFormatter.justDate.string(from: date)
        
        // Predicate to find meals for the selected date with a temporary (negative) ID
        let predicate = #Predicate<Meal> { meal in
            meal.date == dateString && meal.id < 0
        }
        
        let descriptor = FetchDescriptor<Meal>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    
}
