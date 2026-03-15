//
//  HealthKitService.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.03.2026.
//

import Foundation
import HealthKit
import CoreLocation

class HealthKitService {
    
    static let shared = HealthKitService()
    let healthStore = HKHealthStore()
    
    private init() {}
    
    // MARK: - 1. Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw URLError(.cannotConnectToHost) }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    // MARK: - 2. Fetching Workouts
    /// Fetches all workouts that overlap with the given date
    func fetchWorkouts(for date: Date) async throws -> [HKWorkout] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 3. Fetching GPS Route
    /// Fetches all GPS coordinates for a specific workout
    func fetchRouteLocations(for workout: HKWorkout) async throws -> [CLLocation] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        let routes: [HKWorkoutRoute] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: routeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkoutRoute]) ?? [])
            }
            healthStore.execute(query)
        }
        
        guard let route = routes.first else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            var allLocations: [CLLocation] = []
            
            let query = HKWorkoutRouteQuery(route: route) { query, locationsOrNil, done, errorOrNil in
                if let error = errorOrNil {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let locations = locationsOrNil {
                    allLocations.append(contentsOf: locations)
                }
                
                if done {
                    continuation.resume(returning: allLocations)
                }
            }
            healthStore.execute(query)
        }
    }
}
