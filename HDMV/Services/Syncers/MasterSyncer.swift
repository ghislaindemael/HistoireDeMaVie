//
//  MasterSyncer.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//


import Foundation
import SwiftData

@MainActor
class MasterSyncer {
    private let activityInstanceSyncer: ActivityInstanceSyncer
    private let tripLegSyncer: TripLegSyncer
    private let interactionSyncer: PersonInteractionSyncer

    init(modelContext: ModelContext) {
        self.activityInstanceSyncer = ActivityInstanceSyncer(modelContext: modelContext)
        self.tripLegSyncer = TripLegSyncer(modelContext: modelContext)
        self.interactionSyncer = PersonInteractionSyncer(modelContext: modelContext)
    }

    func sync() async {
        do {
            try await activityInstanceSyncer.sync()
            try await tripLegSyncer.sync()
            try await interactionSyncer.sync()
        } catch {
            print("❌ MasterSyncer full sync failed: \(error)")
        }
    }

    func pushChanges() async {
        do {
            _ = try await activityInstanceSyncer.pushChanges()            
            _ = try await tripLegSyncer.pushChanges()
            _ = try await interactionSyncer.pushChanges()
        } catch {
            print("❌ MasterSyncer push failed: \(error)")
        }
    }
}
