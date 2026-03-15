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
    
    func importWorkout(_ workout: HKWorkout) async {
        let newTrip = Trip(
            timeStart: workout.startDate,
            timeEnd: workout.endDate,
            syncStatus: .local
        )
        
        var detailsText = "Imported from Apple Health"
        let totalDistanceMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        if totalDistanceMeters > 0 {
            detailsText += "\nDistance: \(String(format: "%.2f", totalDistanceMeters / 1000)) km"
        }
        newTrip.details = detailsText
        
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
        do {
            try modelContext.save()
            await loadData()
        } catch {
            print("Failed to save imported trip: \(error)")
        }
    }
}
