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
class TripSyncer: BaseLogSyncer<Trip, TripDTO, TripPayload> {
    
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
        return try await tripsService.updateTrip(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        // try await tripService.deleteTrip(id: id)
    }
    
    override func resolveRelationships() throws {
        print("Resolving Trip relationships...")
        
        let instanceLookup: [Int: ActivityInstance] = try getLookupMap()
        let placeLookup: [Int: Place] = try getLookupMap()
        let vehicleLookup: [Int: Vehicle] = try getLookupMap()
        let pathLookup: [Int: Path] = try getLookupMap()
        
        try resolveRelationship(
            for: Trip.self,
            relationshipKeyPath: \Trip.parentInstance,
            ridKeyPath: \Trip.parentInstanceRid,
            lookupMap: instanceLookup
        )
        
        try resolveRelationship(
            for: Trip.self,
            relationshipKeyPath: \Trip.placeStart,
            ridKeyPath: \Trip.placeStartRid,
            lookupMap: placeLookup
        )
        
        try resolveRelationship(
            for: Trip.self,
            relationshipKeyPath: \Trip.placeEnd,
            ridKeyPath: \Trip.placeEndRid,
            lookupMap: placeLookup
        )
        
        try resolveRelationship(
            for: Trip.self,
            relationshipKeyPath: \Trip.vehicle,
            ridKeyPath: \Trip.vehicleRid,
            lookupMap: vehicleLookup
        )
        
        try resolveRelationship(
            for: Trip.self,
            relationshipKeyPath: \Trip.path,
            ridKeyPath: \Trip.pathRid,
            lookupMap: pathLookup
        )
        
        print("All Trip relationships resolved.")
    }
    
}
