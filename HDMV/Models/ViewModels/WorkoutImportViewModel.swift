//
//  WorkoutImportViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.03.2026.
//

import SwiftUI
import HealthKit
import SwiftData

enum ImportTarget {
    case trip
    case activity
}

@MainActor
class WorkoutImportViewModel: ObservableObject {
    @Published var filterDate: Date = .now
    @Published var workouts: [HKWorkout] = []
    
    @Published var localTrips: [Trip] = []
    @Published var localActivities: [ActivityInstance] = []
    
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
            
            let tripPredicate = #Predicate<Trip> {
                $0.timeStart >= startOfDay && $0.timeStart < endOfDay
            }
            let tripDescriptor = FetchDescriptor<Trip>(predicate: tripPredicate)
            localTrips = try modelContext.fetch(tripDescriptor)
            
            let activityPredicate = #Predicate<ActivityInstance> {
                $0.timeStart >= startOfDay && $0.timeStart < endOfDay
            }
            let activityDescriptor = FetchDescriptor<ActivityInstance>(predicate: activityPredicate)
            localActivities = try modelContext.fetch(activityDescriptor)
            
        } catch {
            print("Failed to load workouts: \(error)")
        }
    }
    
    func isImported(_ workout: HKWorkout) -> Bool {
        let tolerance: TimeInterval = 60
        
        let isTrip = localTrips.contains { trip in
            abs(trip.timeStart.timeIntervalSince(workout.startDate)) <= tolerance
        }
        
        let isActivity = localActivities.contains { activity in
            abs(activity.timeStart.timeIntervalSince(workout.startDate)) <= tolerance
        }
        
        return isTrip || isActivity
    }
    
    func importWorkout(_ workout: HKWorkout, as target: ImportTarget) async {
        
        let durationFormatter = DateComponentsFormatter()
        durationFormatter.allowedUnits = [.hour, .minute, .second]
        durationFormatter.unitsStyle = .abbreviated
        let durationStr = durationFormatter.string(from: workout.duration) ?? ""
        
        let totalDistanceMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        var activeEnergy: Double = 0
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
           let energyStat = workout.statistics(for: energyType),
           let sum = energyStat.sumQuantity() {
            activeEnergy = sum.doubleValue(for: .kilocalorie())
        }
        var detailsText = "Imported from Apple Health (\(workout.workoutActivityType.name))\nDuration: \(durationStr)"
        
        if target == .activity {
            // MARK: - Import as ActivityInstance
            
            if activeEnergy > 0 {
                detailsText += "\nCalories: \(Int(activeEnergy)) kcal"
            }
            
            let newActivity = ActivityInstance(
                timeStart: workout.startDate,
                timeEnd: workout.endDate,
                details: detailsText,
                syncStatus: .local
            )
            
            modelContext.insert(newActivity)
            
        } else {
            // MARK: - Import as Trip (Original Logic)
            
            if totalDistanceMeters > 0 {
                detailsText += "\nDistance: \(String(format: "%.2f", totalDistanceMeters / 1000)) km"
            }
            
            let newTrip = Trip(
                timeStart: workout.startDate,
                timeEnd: workout.endDate,
                details: detailsText,
                syncStatus: .local
            )
            
            if let locations = try? await HealthKitService.shared.fetchRouteLocations(for: workout), !locations.isEmpty {
                var coords: [[Double]] = []
                var gain: Double = 0
                var loss: Double = 0
                
                for i in 0..<locations.count {
                    let current = locations[i]
                    coords.append([
                        current.coordinate.longitude,
                        current.coordinate.latitude,
                        current.altitude,
                        current.timestamp.timeIntervalSince1970
                    ])
                    
                    if i > 0 {
                        let previous = locations[i - 1]
                        let diff = current.altitude - previous.altitude
                        if diff > 0 { gain += diff }
                        else if diff < 0 { loss += abs(diff) }
                    }
                }
                
                newTrip.geojsonTrack = GeoJSONLineString(coordinates: coords)
                newTrip.pathMetrics = PathMetrics(
                    distance: totalDistanceMeters,
                    elevationGain: gain,
                    elevationLoss: loss
                )
            } else {
                if totalDistanceMeters > 0 {
                    newTrip.pathMetrics = PathMetrics(distance: totalDistanceMeters)
                }
            }
            
            modelContext.insert(newTrip)
        }
        
        do {
            try modelContext.save()
            await loadData()
        } catch {
            print("Failed to save imported workout: \(error)")
        }
    }
}
