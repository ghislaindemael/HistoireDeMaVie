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
    private let tripSyncer: TripSyncer
    private let interactionSyncer: InteractionSyncer
    private let lifeEventSyncer: LifeEventSyncer

    init(modelContext: ModelContext) {
        self.activityInstanceSyncer = ActivityInstanceSyncer(modelContext: modelContext)
        self.tripSyncer = TripSyncer(modelContext: modelContext)
        self.interactionSyncer = InteractionSyncer(modelContext: modelContext)
        self.lifeEventSyncer = LifeEventSyncer(modelContext: modelContext)
    }

    func sync(
        filterMode: MyActivitiesPageViewModel.FilterMode,
        date: Date,
        activityRid: Int?,
        startDate: Date?,
        endDate: Date?
    ) async {
        do {
            switch filterMode {
                case .byDate:
                    try await activityInstanceSyncer.pullChanges(date: date)
                case .byActivity:
                    guard let actRid = activityRid, let start = startDate, let end = endDate else {
                        print("❌ MasterSyncer: Missing parameters for byActivity sync.")
                        return
                    }
                    try await activityInstanceSyncer.pullChanges(activityRid: actRid, startDate: start, endDate: end)
            }
            
            let primaryDate = (filterMode == .byDate) ? date : startDate ?? date
            try await tripSyncer.pullChanges(date: primaryDate)
            try await interactionSyncer.pullChanges(date: primaryDate)
            try await lifeEventSyncer.pullChanges(date: primaryDate)
            
            try await pushChanges()
            
        } catch {
            print("❌ MasterSyncer full sync failed: \(error)")
        }
    }

    func pushChanges() async throws {
        do {
            _ = try await activityInstanceSyncer.pushChanges()            
            _ = try await tripSyncer.pushChanges()
            _ = try await interactionSyncer.pushChanges()
            _ = try await lifeEventSyncer.pushChanges()
        } catch {
            print("❌ MasterSyncer push failed: \(error)")
        }
    }
}
