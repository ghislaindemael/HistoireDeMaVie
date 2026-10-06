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
    private let quoteSyncer: QuoteSyncer
    private let transactionSyncer: TransactionSyncer

    init(modelContext: ModelContext) {
        self.activityInstanceSyncer = ActivityInstanceSyncer(modelContext: modelContext)
        self.tripSyncer = TripSyncer(modelContext: modelContext)
        self.interactionSyncer = InteractionSyncer(modelContext: modelContext)
        self.lifeEventSyncer = LifeEventSyncer(modelContext: modelContext)
        self.quoteSyncer = QuoteSyncer(modelContext: modelContext)
        self.transactionSyncer = TransactionSyncer(modelContext: modelContext)
    }

    func sync(
        filterMode: TimelineFilterMode,
        date: Date,
        activityRid: Int? = nil,
        personRid: Int? = nil,
        transactionTypeRid: Int? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async {
        guard NetworkMonitor.shared.isConnected else {
            print("⚠️ MasterSyncer: Skipping sync, no network connection.")
            ToastManager.shared.showToast(message: "No Internet Connection", systemImage: "wifi.exclamationmark", color: .orange)
            return
        }
        
        do {
            switch filterMode {
                case .daily:
                    try await activityInstanceSyncer.pullChanges(date: date)
                    try await interactionSyncer.pullChanges(date: date)
                    try await tripSyncer.pullChanges(date: date)
                    try await lifeEventSyncer.pullChanges(date: date)
                    try await quoteSyncer.pullChanges(date: date)
                    try await transactionSyncer.pullChanges(date: date)
                case .advanced:
                    guard let start = startDate, let end = endDate else {
                        print("❌ MasterSyncer: Missing date parameters for advanced sync.")
                        return
                    }
                    
                    if let actRid = activityRid {
                        try await activityInstanceSyncer.pullChanges(activityRid: actRid, startDate: start, endDate: end)
                    }
                    
                    if let pRid = personRid {
                        try await interactionSyncer.pullChanges(personRid: pRid, startDate: start, endDate: end)
                    }
                    
                    if let tRid = transactionTypeRid {
                        try await transactionSyncer.pullChanges(transactionTypeRid: tRid, startDate: start, endDate: end)
                    }
            }
            
            try await pushChanges()
            
        } catch {
            print("❌ MasterSyncer full sync failed: \(error)")
            ToastManager.shared.showToast(message: "Sync Failed", systemImage: "xmark.icloud", color: .red)
        }
    }

    func pushChanges() async throws {
        guard NetworkMonitor.shared.isConnected else {
            print("⚠️ MasterSyncer: Skipping push, no network connection.")
            ToastManager.shared.showToast(message: "No Internet Connection", systemImage: "wifi.exclamationmark", color: .orange)
            return
        }
        
        do {
            _ = try await activityInstanceSyncer.pushChanges()            
            _ = try await tripSyncer.pushChanges()
            _ = try await interactionSyncer.pushChanges()
            _ = try await lifeEventSyncer.pushChanges()
            _ = try await quoteSyncer.pushChanges()
            _ = try await transactionSyncer.pushChanges()
        } catch {
            print("❌ MasterSyncer push failed: \(error)")
            ToastManager.shared.showToast(message: "Push Failed", systemImage: "arrow.up.icloud", color: .red)
        }
    }
}
