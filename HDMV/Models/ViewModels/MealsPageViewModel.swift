//
//  MealsViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.07.2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class MealsPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private var networkStatusBinding: PropertyBinder<MealsPageViewModel, Bool>?
    @Published var isOnline: Bool = false
    
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    
    private var mealService = MealService()
    @Published private(set) var mealTypes: [MealType] = []
    private var localMeals: [Meal] = []
    private var onlineMeals: [Meal] = []
    @Published var allMeals: [Meal] = []
    
    
    init() {
        self.networkStatusBinding = PropertyBinder(syncingNetworkStatusTo: \.isOnline, on: self)
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadMealTypes()
            await loadData()
        }
    }
    
    // MARK: - Data Flow Orchestration
    
    private func loadMealTypes() async {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<MealType>(sortBy: [SortDescriptor(\.name)])
            self.mealTypes = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch meal types: \(error)")
        }
    }
    
    func loadData() async {
        isLoading = true
        if isOnline {
            await fetchOnlineMeals()
        }
        fetchLocalMeals()
        mergeMeals()
        isLoading = false
    }
    
    private func fetchOnlineMeals() async {
        do {
            let mealDtos = try await mealService.fetchMeals(for: selectedDate)
            self.onlineMeals = dtosToMealObjects(from: mealDtos)
        } catch {
            print("Failed to fetch online meals. Showing local only;\n\(error.localizedDescription)")
            self.onlineMeals = []
        }
    }
    
    private func fetchLocalMeals() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        do {
            let descriptor = FetchDescriptor<Meal>(
                predicate: #Predicate { meal in
                    meal.time_start >= startOfDay && meal.time_start < endOfDay
                },
                sortBy: [
                    SortDescriptor(\.time_start),
                    SortDescriptor(\.mealTypeId)
                ]
            )
            self.localMeals = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    
    private func mergeMeals() {
        let combined = localMeals + onlineMeals
        
        var seenIDs = Set<Int>()
        let unique = combined.filter { meal in
            if seenIDs.contains(meal.id) {
                return false
            } else {
                seenIDs.insert(meal.id)
                return true
            }
        }
        
        unique.forEach { meal in
            meal.mealType = mealTypes.first(where: { $0.id == meal.mealTypeId })
        }
        
        self.allMeals = unique.sorted {
            ($0.time_start, $0.mealTypeId) < ($1.time_start, $1.mealTypeId)
        }
    }

    
    // MARK: User actions
    
    func createNewMeal(at startDate: Date? = nil) {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        
        let start: Date
        if let date = startDate {
            start = calendar.date(
                bySettingHour: 12,
                minute: 0,
                second: 0,
                of: date
            ) ?? Date()
        } else {
            start = Date()
        }
        
        let newMeal = Meal(
            id: generateTempID(),
            time_start: start,
            time_end: nil,
            content: nil,
            mealTypeId: 0,
            syncStatus: .local
        )
        
        context.insert(newMeal)
        try? context.save()
        
        Task { await loadData() }
    }

    
    func endMeal(_ meal: Meal) {
        meal.time_end = .now
        if meal.syncStatus == .synced {
            meal.syncStatus = .local
        }
        try? modelContext?.save()
        Task { await loadData() }
    }
    
    func syncChanges() async {
        guard let context = modelContext, isOnline else { return }
        
        self.isLoading = true
        let dirtyMeals = localMeals.filter { $0.syncStatus == .local || $0.syncStatus == .failed }
        
        guard !dirtyMeals.isEmpty else {
            await loadData()
            return
        }
        
        for meal in dirtyMeals {
            meal.syncStatus = .syncing
            
            do {
                if meal.mealTypeId == 0 {
                    meal.syncStatus = .local
                    try context.save()
                    continue
                }
                
                if meal.id < 0 {
                    let payload = NewMealPayload(fromMeal: meal)
                    let insertedDto = try await mealService.insertMeal(payload)
                    let newSyncedMeal = Meal(fromDTO: insertedDto)
                    
                    context.delete(meal)
                    localMeals.removeAll { $0.id == meal.id }
                    
                    onlineMeals.append(newSyncedMeal)
                    
                } else {
                    let dto = MealDTO(from: meal)
                    let success = try await mealService.updateMeal(mealDto: dto)
                    
                    if success {
                        localMeals.removeAll { $0.id == meal.id }
                        context.delete(meal)
                        
                        meal.syncStatus = .synced
                        onlineMeals.append(meal)
                    } else {
                        meal.syncStatus = .failed
                    }
                }
                
                try context.save()
                
            } catch {
                print("❌ Sync error for meal \(meal.id): \(error)")
                meal.syncStatus = .failed
                try? context.save()
            }
        }
        
        await loadData()
    }

    
    
    func updateMealLocally(_ updatedMeal: Meal) {
        guard let context = modelContext else { return }
        
        if updatedMeal.syncStatus == .synced {
            onlineMeals.removeAll { $0.id == updatedMeal.id }
            
            updatedMeal.syncStatus = .local
            context.insert(updatedMeal)
            
            if !localMeals.contains(where: { $0.id == updatedMeal.id }) {
                localMeals.append(updatedMeal)
            }
            
        } else {
            updatedMeal.syncStatus = .local
        }
        
        try? context.save()
        
        mergeMeals()
        Task {
            await syncChanges()
        }
    }




    
    // MARK: - Helpers
    
    private func generateTempID() -> Int {
        let minID = allMeals.map(\.id).filter { $0 < 0 }.min() ?? 0
        return minID - 1
    }
    
    private func mergeDateWithCurrentTime() -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: .now)
        
        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year
        finalComponents.month = dateComponents.month
        finalComponents.day = dateComponents.day
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        finalComponents.second = timeComponents.second
        
        return calendar.date(from: finalComponents)
    }
    
    func hasUnsyncedChanges() -> Bool {
        return allMeals.contains { $0.syncStatus != .synced }
    }
}
