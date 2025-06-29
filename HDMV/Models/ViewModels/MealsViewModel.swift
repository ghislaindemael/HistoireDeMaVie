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
    
    @Published var isOnline: Bool = true
    
    private let mealService = MealService()
    // Get a direct reference to the main database context from our shared container
    private let modelContext: ModelContext
    
    private var cachedMealTypes: [MealType] {
        CachingService.shared.cachedMealTypes
    }
    
    init() {
        self.modelContext = HDMVApp.sharedModelContainer.mainContext
        self.isOnline = NetworkMonitor.shared.isConnected
    }
    
    // MARK: - Core Data Logic
    
    func fetchMealsForSelectedDate() async {
        isLoading = true
        errorMessage = nil
        
        await CachingService.shared.ensureCacheIsLoaded()
        
        do {
            let remoteMeals: [Meal]
            if isOnline {
                async let remoteMealsTask = mealService.fetchMeals(for: selectedDate)
                let remoteDTOs = try await remoteMealsTask
                remoteMeals = dtosToMealObjects(from: remoteDTOs)
                remoteMeals.forEach { $0.syncStatus = .synced }
            } else {
                remoteMeals = []
            }
            // 2. Fetch locally saved, unsynced meals from SwiftData
            let localMeals = try fetchLocalUnsyncedMeals(for: selectedDate)
            
            // 3. Merge the lists, preventing duplicates
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
        if isOnline {
            Task {
                await uploadNewMeal(meal)
            }
        }
    }
    
    func endMealNow(for meal: Meal) {
        // 1. Find the meal in the view model's published array.
        guard let index = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        
        // 2. Create the timestamp and update the meal's properties in the array.
        // This will instantly update any view observing the 'meals' array.
        let nowString = timeFormatter.string(from: Date())
        meals[index].timeEnd = nowString
        meals[index].syncStatus = .syncing
        
        // 3. Persist this change to the local SwiftData store immediately.
        do {
            try modelContext.save()
        } catch {
            print("Failed to save ended meal locally: \(error)")
            // If saving fails, revert the status to indicate an error.
            meals[index].syncStatus = .failed
            return
        }
        
        // 4. Start the background task to sync the update with Supabase.
        if isOnline {
            Task {
                await self.syncExistingMealUpdate(mealId: meal.id)
            }
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
            meals[index].timeEnd = meal.timeEnd
            
            if isOnline {
                meals[index].syncStatus = .syncing
                Task {
                    await self.syncExistingMealUpdate(mealId: meal.id)
                }
            } else {
                meals[index].syncStatus = .local
            }
        }
    }
    
    
    /// Retries uploading a meal that previously failed.
    func retryUpload(for meal: Meal) {
        guard isOnline, let index = meals.firstIndex(where: { $0.id == meal.id }) else {
            errorMessage = "No internet connection. Please try again later."
            return
        }
        
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
        
        guard isOnline else {
            if let index = meals.firstIndex(where: { $0.id == meal.id }) {
                objectWillChange.send()
                meals[index].syncStatus = .failed
            }
            return
        }

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
                
                let finalMeal = dtosToMealObjects(from: [insertedDto]).first!
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
    
    private func syncExistingMealUpdate(mealId: Int) async {
        guard isOnline, let mealForDto = meals.first(where: { $0.id == mealId }) else {
            if let index = meals.firstIndex(where: { $0.id == mealId }) {
                objectWillChange.send()
                meals[index].syncStatus = .failed
            }
            return
        }
        
        let mealDto = mealToDTO(mealForDto)
        
        do {
            let didUpdateSuccessfully = try await mealService.updateMeal(mealDto)
            
            if let index = meals.firstIndex(where: { $0.id == mealId }) {
                objectWillChange.send()
                
                if didUpdateSuccessfully {
                    meals[index].syncStatus = .synced
                } else {
                    print("Update sent, but no matching meal was found on the server.")
                    meals[index].syncStatus = .failed
                }
            }
        } catch {
            if let index = meals.firstIndex(where: { $0.id == mealId }) {
                objectWillChange.send()
                meals[index].syncStatus = .failed
            }
            print("Failed to execute update request: \(error)")
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
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    
}
