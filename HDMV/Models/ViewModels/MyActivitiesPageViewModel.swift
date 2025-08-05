//
//  MyActivitiesPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import Foundation
import SwiftData

@MainActor
class MyActivitiesPageViewModel: ObservableObject {
    
    private var modelContext: ModelContext?
    private let instanceService = ActivityInstanceService()
    private let tripLegsService = TripsService()
    @Published var isLoading: Bool = false
    
    @Published var selectedDate: Date = .now
    @Published var instances: [ActivityInstance] = []
    @Published var tripLegs: [TripLeg] = []
    
    @Published var activityTree: [Activity] = []
    @Published var vehicles: [Vehicle] = []
    @Published var cities: [City] = []
    @Published var places: [Place] = []
    @Published var vehicleTypes: [VehicleType] = []
    
    var hasLocalChanges: Bool {
        let instancesChanged = instances.contains { $0.syncStatus != .synced }
        let tripsChanged = tripLegs.contains { $0.syncStatus != .synced }
        return instancesChanged || tripsChanged
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchActivities()
        fetchCatalogueData()
    }
    
    private func fetchActivities() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Activity>(sortBy: [SortDescriptor(\.name)])
            self.activityTree = Activity.buildTree(from: try context.fetch(descriptor))
        } catch {
            print("Failed to fetch activities: \(error)")
        }
    }
    
    private func fetchTripLegs() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        let predicate = #Predicate<TripLeg> {
            $0.time_start >= startOfDay && $0.time_start < endOfDay
        }
        
        do {
            let descriptor = FetchDescriptor<TripLeg>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.time_start)]
            )
            self.tripLegs = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch trip legs: \(error)")
        }
    }
    
    
    private func fetchCatalogueData() {
        guard let context = modelContext else { return }
        do {
            self.vehicles = try context.fetch(FetchDescriptor<Vehicle>(sortBy: [SortDescriptor(\.name)]))
            self.cities = try context.fetch(FetchDescriptor<City>(sortBy: [SortDescriptor(\.rank), SortDescriptor(\.name)]))
            self.places = try context.fetch(FetchDescriptor<Place>(sortBy: [SortDescriptor(\.name)]))
            self.vehicleTypes = try context.fetch(FetchDescriptor<VehicleType>())
        } catch {
            print("Failed to fetch catalogue data: \(error)")
        }
    }
    
    // MARK: Transmitted data
    
    func findVehicle(by id: Int?) -> Vehicle? {
        guard let id = id else { return nil }
        return vehicles.first { $0.id == id }
    }
    
    /// Helper function to find an activity by its ID in the tree.
    func findActivity(by id: Int?) -> Activity? {
        guard let id = id else { return nil }
        return activityTree.flatMap { $0.flattened() }.first { $0.id == id }
    }
    
    func tripLegs(for instanceId: Int) -> [TripLeg] {
        return self.tripLegs.filter { $0.parent_id == instanceId }
    }
    
    func tripsVehicles(for tripLegs: [TripLeg]) -> [Vehicle] {
        let vehicleIds = Set(tripLegs.compactMap { $0.vehicle_id })
        return self.vehicles.filter { vehicleIds.contains($0.id) }
    }
    
    func tripsPlaces(for tripLegs: [TripLeg]) -> [Place] {
        let startPlaceIds = tripLegs.compactMap { $0.place_start_id }
        let endPlaceIds = tripLegs.compactMap { $0.place_end_id }
        let allPlaceIds = Set(startPlaceIds + endPlaceIds)
        return self.places.filter { allPlaceIds.contains($0.id) }
    }
    
    func findPlace(by id: Int?) -> Place? {
        guard let id = id else { return nil }
        return places.first { $0.id == id }
    }
    
    func tripsVehicleTypes(for vehicles: [Vehicle]) -> [VehicleType] {
        let typeIds = Set(vehicles.map { $0.type })
        return self.vehicleTypes.filter { typeIds.contains($0.id) }
    }
    
    func unassignedTripLegs() -> [TripLeg] {
        return self.tripLegs.filter { $0.parent_id == nil || $0.parent_id! < 0}
    }
    
    // MARK: - Core Synchronization Logic
    
    func syncWithServer() async {
        isLoading = true
        await syncActivityInstances()
        await syncTripLegs()
        
        isLoading = false
    }
    
    private func syncActivityInstances() async {
        
        guard let context = modelContext else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = #Predicate<ActivityInstance> { $0.time_start >= startOfDay && $0.time_start < endOfDay }
        
        do {
            let onlineInstances = try await instanceService.fetchActivityInstances(for: selectedDate)
            let onlineDict = Dictionary(uniqueKeysWithValues: onlineInstances.map { ($0.id, $0) })
            
            let descriptor = FetchDescriptor<ActivityInstance>(predicate: predicate)
            let localInstances = try context.fetch(descriptor)
            let localDict = Dictionary(uniqueKeysWithValues: localInstances.map { ($0.id, $0) })
            
            for dto in onlineInstances {
                if let localInstance = localDict[dto.id] {
                    if localInstance.syncStatus == .synced {
                        localInstance.update(fromDto: dto)
                    }
                } else {
                    context.insert(ActivityInstance(fromDto: dto))
                }
            }
            
            for localInstance in localInstances {
                if onlineDict[localInstance.id] == nil && localInstance.syncStatus == .synced {
                    context.delete(localInstance)
                }
            }
            
            try context.save()
            
            let refreshedDescriptor = FetchDescriptor<ActivityInstance>(predicate: predicate, sortBy: [SortDescriptor(\.time_start, order: .reverse)])
            self.instances = try context.fetch(refreshedDescriptor)
        } catch {
            print("Error during instance sync: \(error)")
        }
    }
    
    private func syncTripLegs() async {
        guard let context = modelContext else { return }
        
        do {
            let onlineTripLegs = try await tripLegsService.fetchTripLegs(for: selectedDate)
            let onlineDict = Dictionary(uniqueKeysWithValues: onlineTripLegs.map { ($0.id, $0) })
            
            let startOfDay = Calendar.current.startOfDay(for: selectedDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = #Predicate<TripLeg> { trip in
                trip.time_start >= startOfDay && trip.time_start < endOfDay
            }
            let descriptor = FetchDescriptor<TripLeg>(predicate: predicate)
            let localTripLegs = try context.fetch(descriptor)
            let localDict = Dictionary(uniqueKeysWithValues: localTripLegs.map { ($0.id, $0) })
            
            for dto in onlineTripLegs {
                if let localLeg = localDict[dto.id] {
                    switch localLeg.syncStatus {
                        case .synced:
                            localLeg.update(fromDto: dto)
                        case .local:
                            break
                        default:
                            break
                    }
                } else {
                    context.insert(TripLeg(fromDto: dto))
                }
            }
            
            for localLeg in localTripLegs {
                if onlineDict[localLeg.id] == nil && localLeg.syncStatus == .synced {
                    context.delete(localLeg)
                }
            }
            
            try context.save()
            
            let refreshedDescriptor = FetchDescriptor<TripLeg>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.time_start)]
            )
            self.tripLegs = try context.fetch(refreshedDescriptor)
            
        } catch {
            print("Error during trip leg sync: \(error)")
        }
    }
    
    
    func syncChanges() async {
        guard let context = modelContext else { return }
        
        let instancesToSync = self.instances.filter { $0.syncStatus != .synced }
        let tripsToSync = self.tripLegs.filter { $0.syncStatus != .synced }
        
        guard !instancesToSync.isEmpty || !tripsToSync.isEmpty else { return }
        
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            for instance in instancesToSync {
                group.addTask {
                    await self.sync(instance: instance, in: context)
                }
            }
            for trip in tripsToSync {
                group.addTask {
                    await self.sync(tripLeg: trip, in: context)
                }
            }
        }
        
        try? context.save()
        isLoading = false
    }
    
    private func sync(instance: ActivityInstance, in context: ModelContext) async {
        let payload = ActivityInstancePayload(
            time_start: instance.time_start, time_end: instance.time_end,
            activity_id: instance.activity_id, details: instance.details,
            activity_details: instance.decodedActivityDetails
        )
        do {
            if instance.id < 0 {
                let temporaryId = instance.id
                let newDTO = try await self.instanceService.createActivityInstance(payload)
                instance.id = newDTO.id
                
                updateTripLegsParentId(from: temporaryId, to: newDTO.id)
                
            } else {
                _ = try await self.instanceService.updateActivityInstance(id: instance.id, payload: payload)
            }
            instance.syncStatus = .synced
        } catch {
            instance.syncStatus = .failed
            print("Failed to sync instance \(instance.id): \(error).")
        }
    }
    
    private func updateTripLegsParentId(from oldId: Int, to newId: Int) {
        guard let context = modelContext else { return }
        let children = self.tripLegs.filter { $0.parent_id == oldId }
        for child in children {
            child.parent_id = newId
        }
        try? context.save()
    }
    
    func claim(tripLeg: TripLeg, for instance: ActivityInstance) {
        guard let context = modelContext else { return }
        
        if let legToUpdate = self.tripLegs.first(where: { $0.id == tripLeg.id }) {
            legToUpdate.parent_id = instance.id
            legToUpdate.syncStatus = .local
            try? context.save()
        }
    }
    
    
    private func sync(tripLeg: TripLeg, in context: ModelContext) async {
        let payload = TripLegPayload(
            parent_id: tripLeg.parent_id, time_start: tripLeg.time_start,
            time_end: tripLeg.time_end, vehicle_id: tripLeg.vehicle_id,
            place_start_id: tripLeg.place_start_id, place_end_id: tripLeg.place_end_id,
            am_driver: tripLeg.am_driver, path_str: tripLeg.path_str, details: tripLeg.details
        )
        
        do {
            if tripLeg.id < 0 {
                let newDTO = try await self.tripLegsService.createTrip(payload)
                tripLeg.id = newDTO.id
            } else {
                _ = try await self.tripLegsService.updateTrip(id: tripLeg.id, payload: payload)
            }
            tripLeg.syncStatus = .synced
        } catch {
            print("-> ERROR: Failed to sync trip leg \(tripLeg.id): \(error). Marking as failed.")
            tripLeg.syncStatus = .failed
        }
    }
    
    // MARK: - Local Cache Creation
    
    func createNewTripLegInCache(parent_id: Int) {
        guard let context = modelContext else { return }
        let newLeg = TripLeg(
            id: Int.random(in: -999999 ... -1),
            parent_id: parent_id,
            time_start: .now
        )
        context.insert(newLeg)
        do {
            try context.save()
            self.tripLegs.insert(newLeg, at: 0)
        } catch {
            print("Failed to create new trip: \(error)")
        }
    }
    
    func endTripLeg(leg: TripLeg){
        guard let context = modelContext else { return }
        do {
            leg.time_end = .now
            leg.syncStatus = .local
            try context.save()
        } catch {
            print("Failed to end trip.")
        }
    }
    
    func endActivityInstance(instance: ActivityInstance){
        guard let context = modelContext else { return }
        do {
            instance.time_end = .now
            instance.syncStatus = .local
            try context.save()
        } catch {
            print("Failed to end activity.")
        }
    }
    
    func createNewInstanceInCache() {
        guard let context = modelContext else { return }
        let newInstance = ActivityInstance(id: Int.random(in: -999999 ... -1), time_start: .now, syncStatus: .local)
        context.insert(newInstance)
        do {
            try context.save()
            self.instances.insert(newInstance, at: 0)
        } catch {
            print("Failed to save new instance: \(error)")
        }
    }
    
    func createNewInstanceAtNoonInCache() {
        guard let context = modelContext else { return }
        let noonOnSelectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let newInstance = ActivityInstance(id: Int.random(in: -999999 ... -1), time_start: noonOnSelectedDate, syncStatus: .local)
        context.insert(newInstance)
        do {
            try context.save()
            self.instances.append(newInstance)
            self.instances.sort { $0.time_start > $1.time_start }
        } catch {
            print("Failed to save new instance at noon: \(error)")
        }
    }
    
    
}
