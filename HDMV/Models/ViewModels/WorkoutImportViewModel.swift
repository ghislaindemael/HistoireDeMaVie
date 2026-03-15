//
//  WorkoutImportViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.03.2026.
//


import SwiftUI
import HealthKit
import SwiftData

@MainActor
class WorkoutImportViewModel: ObservableObject {
    @Published var filterDate: Date = .now
    @Published var workouts: [HKWorkout] = []
    @Published var localTrips: [Trip] = []
    @Published var isLoading: Bool = false
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await HealthKitService.shared.requestAuthorization()
            
            workouts = try await HealthKitService.shared.fetchWorkouts(for: filterDate)
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: filterDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = #Predicate<Trip> {
                $0.timeStart >= startOfDay && $0.timeStart < endOfDay
            }
            
            let descriptor = FetchDescriptor<Trip>(predicate: predicate)
            localTrips = try modelContext.fetch(descriptor)
            
        } catch {
            print("Failed to load workouts: \(error)")
        }
    }
    
    func isImported(_ workout: HKWorkout) -> Bool {
        localTrips.contains { trip in
            trip.timeStart == workout.startDate
        }
    }
    
    func importWorkout(_ workout: HKWorkout) {
        let newTrip = Trip(from: workout)
        modelContext.insert(newTrip)
        
        do {
            try modelContext.save()
            Task { await loadData() }
        } catch {
            print("Failed to save imported trip: \(error)")
        }
    }
}
