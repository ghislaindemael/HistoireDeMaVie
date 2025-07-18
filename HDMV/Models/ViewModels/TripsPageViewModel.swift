//
//  TripsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 23.06.2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
class TripsPageViewModel: ObservableObject {
    
    @Published var displayTrips: [TripDisplayModel] = []
    @Published var selectedDate: Date = .now
    @Published var isLoading: Bool = false
        
    private var onlineTrips: [TripDTO] = []
    private var localTrips: [Trip] = []
    
    private var modelContext: ModelContext?
    private let tripsService = TripsService()
    
    var hasLocalTrips: Bool {
        displayTrips.contains(where: { $0.isLocal })
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Data Flow Orchestration
    
    func loadData() async {
        isLoading = true
        await fetchOnlineTrips()
        mergeAndDisplayTrips()
        isLoading = false
    }
    
    func localCacheDidChange(_ newLocalTrips: [Trip]) {
        self.localTrips = newLocalTrips
        mergeAndDisplayTrips()
    }
    
    private func fetchOnlineTrips() async {
        do {
            self.onlineTrips = try await tripsService.fetchTrips(for: selectedDate)
        } catch {
            print("Failed to fetch online trips. Showing local changes only. Error: \(error)")
            self.onlineTrips = [] // On network failure, we only show local items.
        }
    }
    
    private func mergeAndDisplayTrips() {
        var mergedDict: [Int: TripDisplayModel] = [:]
        
        for dto in onlineTrips {
            guard let id = dto.id else { continue }
            mergedDict[id] = TripDisplayModel(dto: dto)
        }
        
        for trip in localTrips {
            mergedDict[trip.id] = TripDisplayModel(model: trip)
        }
        
        self.displayTrips = Array(mergedDict.values).sorted { $0.time_start > $1.time_start }
    }
    
    // MARK: - User Actions & Offline Caching

    func createNewTripInCache() {
        guard let context = modelContext else { return }
        let newTrip = Trip(
            id: Int.random(in: -999999 ... -1),
            time_start: .now,
            syncStatus: .local
        )
        context.insert(newTrip)
        try? context.save()
    }
    
    /// When a user edits a trip, this ensures it exists in the local "outbox" for saving.
    func prepareForEdit(trip displayTrip: TripDisplayModel) -> Trip? {
        guard let context = modelContext else { return nil }
        
        let targetID = displayTrip.id
        let predicate = #Predicate<Trip> { trip in
            trip.id == targetID
        }
        let descriptor = FetchDescriptor<Trip>(predicate: predicate)
        
        if let existingLocalTrip = try? context.fetch(descriptor).first {
            return existingLocalTrip
        }
        
        let tripToEdit = Trip(
            id: displayTrip.id, time_start: displayTrip.time_start, time_end: displayTrip.time_end,
            vehicle_id: displayTrip.vehicle_id, place_start_id: displayTrip.place_start_id,
            place_end_id: displayTrip.place_end_id, syncStatus: .local
        )
        context.insert(tripToEdit)
        
        // By creating a local copy for editing, we are taking it "offline".
        onlineTrips.removeAll { $0.id == displayTrip.id }
        try? context.save()
        
        return tripToEdit
    }
    
    
    // MARK: - Synchronization
        
    func syncChanges() async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Trip>()
        guard let tripsToSync = try? context.fetch(descriptor), !tripsToSync.isEmpty else {
            return
        }
        
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            for trip in tripsToSync {
                group.addTask {
                    let payload = TripPayload(
                        time_start: trip.time_start,
                        time_end: trip.time_end,
                        vehicle_id: trip.vehicle_id,
                        place_start_id: trip.place_start_id,
                        place_end_id: trip.place_end_id,
                        am_driver: trip.am_driver,
                        path_str: trip.path_str,
                        details: trip.details
                    )
                    do {
                        if trip.id < 0 {
                            _ = try await self.tripsService.createTrip(payload)
                        } else {
                            _ = try await self.tripsService.updateTrip(id: trip.id, payload: payload)
                        }
                        context.delete(trip)
                    } catch {
                        print("Failed to sync trip \(trip.id): \(error).")
                        trip.syncStatus = .failed
                    }
                }
            }
        }
        
        try? context.save()
        
        await loadData()
    }
    
    func saveTrip(_ tripToSave: Trip) {
        guard let context = modelContext else { return }
        
        // Check if a trip with this ID already exists in the local cache
        let targetID = tripToSave.id
        let predicate = #Predicate<Trip> { $0.id == targetID }
        let descriptor = FetchDescriptor<Trip>(predicate: predicate)
        
        if let existingTrip = try? context.fetch(descriptor).first {
            // If it exists, update its properties
            existingTrip.time_start = tripToSave.time_start
            existingTrip.time_end = tripToSave.time_end
            existingTrip.vehicle_id = tripToSave.vehicle_id
            existingTrip.place_start_id = tripToSave.place_start_id
            existingTrip.place_end_id = tripToSave.place_end_id
            existingTrip.am_driver = tripToSave.am_driver
            existingTrip.path_str = tripToSave.path_str
            existingTrip.details = tripToSave.details
            existingTrip.syncStatus = .local
        } else {
            // If it's a new trip (i.e., it was an online trip), insert it.
            context.insert(tripToSave)
        }
        
        // The .onChange handler in the View will automatically update the UI.
        try? context.save()
    }
    
}
