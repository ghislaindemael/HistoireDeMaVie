//
//  PathDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
class ActivityInstanceDetailSheetViewModel: BaseDetailSheetViewModel<ActivityInstance, ActivityInstanceEditor> {
    
    @Published private(set) var tripsForDate: [Trip] = []
    @Published private(set) var interactionsForDate: [Interaction] = []
    
    init(
        model: ActivityInstance,
        modelContext: ModelContext,
        trips: [Trip],
        interactions: [Interaction]
    ) {
        self.tripsForDate = trips
        self.interactionsForDate = interactions
        super.init(model: model, modelContext: modelContext)
    }

    var unclaimedTrips: [Trip] {
        tripsForDate.filter { $0.parentInstance == nil }
    }
    
    var unclaimedInteractions: [Interaction] {
        interactionsForDate.filter { $0.parentInstance == nil }
    }
    
    func claim(trip: Trip, for instance: ActivityInstance) {
        
        do {
            trip.parentInstance = instance
            trip.markAsModified()
            try modelContext.save()
        } catch {
            print("Failed to claim trip: \(error)")
        }
    }
    
}
