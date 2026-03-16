//
//  Trip+HKWorkout.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.03.2026.
//


import HealthKit
import SwiftData

extension Trip {
    
    /// Creates a Trip directly from an Apple Health Workout
    convenience init(from workout: HKWorkout) {
        self.init(
            timeStart: workout.startDate,
            timeEnd: workout.endDate,
            syncStatus: .unsynced
        )
        
        var detailsText = "Imported from Apple Health"
        
        if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
            detailsText += "\nDistance: \(String(format: "%.2f", distance / 1000)) km"
        }
        
        self.details = detailsText
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Run"
        case .walking: return "Walk"
        case .cycling: return "Cycle"
        case .swimming: return "Swim"
        case .elliptical: return "Treadmill/Elliptical"
        case .other: return "Other Workout"
        default: return "Workout"
        }
    }
}
