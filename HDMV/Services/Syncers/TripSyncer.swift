//
//  TripSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


import Foundation
import SwiftData
import SwiftUI

@MainActor
class TripSyncer: BaseSyncer<Trip, TripDTO, TripPayload> {
    
    private let tripsService = TripsService()
    
    // MARK: - Implemented Network Methods
    
    override func fetchRemoteModels(date: Date?) async throws -> [TripDTO] {
        if let date = date {
            return try await tripsService.fetchTrips(for: date)
        }
        fatalError("No date passed in fetchRemoteModels")
    }
    
    override func createOnServer(payload: TripPayload) async throws -> TripDTO {
        return try await tripsService.createTrip(payload)
    }
    
    override func updateOnServer(rid: Int, payload: TripPayload) async throws -> TripDTO {
        return try await tripsService.updateTrip(id: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        // try await tripService.deleteTrip(id: id)
    }
    
    override func resolveRelationships() throws {
        print("⚙️ Resolving relationships for Trips...")
        let tripsToResolve = try modelContext.fetch(FetchDescriptor<Trip>())
        
        let instances = try modelContext.fetch(FetchDescriptor<ActivityInstance>())
        let instanceCache = Dictionary(instances.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil },
                                       uniquingKeysWith: { first, _ in first })
        
        let places = try modelContext.fetch(FetchDescriptor<Place>())
        let placeCache = Dictionary(places.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil },
                                    uniquingKeysWith: { first, _ in first })
        
        let vehicles = try modelContext.fetch(FetchDescriptor<Vehicle>())
        let vehicleCache = Dictionary(vehicles.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil },
                                      uniquingKeysWith: { first, _ in first })
        
        let paths = try modelContext.fetch(FetchDescriptor<Path>())
        let pathCache = Dictionary(paths.compactMap { $0.rid != nil ? ($0.rid!, $0) : nil },
                                   uniquingKeysWith: { first, _ in first })
        
        var linksMade = 0
        for trip in tripsToResolve {
            if trip.parentInstance == nil, let rid = trip.parentInstanceRid {
                if let parent = instanceCache[rid] {
                    trip.parentInstance = parent
                    linksMade += 1
                }
            }
            // Link Vehicle
            if trip.vehicle == nil, let rid = trip.vehicleRid {
                if let vehicle = vehicleCache[rid] {
                    trip.vehicle = vehicle
                    linksMade += 1
                }
            }
            // Link Place Start
            if trip.placeStart == nil, let rid = trip.placeStartRid {
                if let place = placeCache[rid] {
                    trip.placeStart = place
                    linksMade += 1
                }
            }
            // Link Place End
            if trip.placeEnd == nil, let rid = trip.placeEndRid {
                if let place = placeCache[rid] {
                    trip.placeEnd = place
                    linksMade += 1
                }
            }
            // Link Path
            if trip.path == nil, let rid = trip.pathRid {
                if let path = pathCache[rid] {
                    trip.path = path
                    linksMade += 1
                }
            }
        } // End loop
        
        if linksMade > 0 {
            print("✅ Resolved \(linksMade) relationships for Trips.")
        }
        // Save happens in pullChanges after this method returns.
    }
}
