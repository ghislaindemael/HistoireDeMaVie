//
//  AutoPushService.swift
//  HDMV
//

import Combine
import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// Coordinates automatic background pushes of local SwiftData changes to Supabase
/// so external clients (such as the web app) stay up to date.
@MainActor
final class AutoPushService: ObservableObject {
    static let shared = AutoPushService()

    @Published private(set) var isPushing = false

    private var modelContainer: ModelContainer?
    private var networkCancellable: AnyCancellable?
    private var wasConnected = NetworkMonitor.shared.isConnected

    private init() {
        networkCancellable = NetworkMonitor.shared.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                guard let self else { return }
                let reconnected = !self.wasConnected && isConnected
                self.wasConnected = isConnected
                if reconnected {
                    Task { @MainActor in
                        await self.triggerAutoPush(reason: "network restored")
                    }
                }
            }
    }

    /// Registers the shared SwiftData container used for background pushes.
    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Pushes pending local changes silently if auto-push is enabled, authenticated, and online.
    func triggerAutoPush(reason: String) async {
        guard SettingsStore.shared.autoPushEnabled else { return }
        guard SupabaseService.shared.isAuthenticated else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        guard !isPushing else { return }
        guard let modelContainer else { return }

        isPushing = true
        defer { isPushing = false }

        #if canImport(UIKit)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "HDMVAutoPush") {
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
                backgroundTaskId = .invalid
            }
        }
        defer {
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
            }
        }
        #endif

        print("🔄 AutoPushService: Starting auto-push (\(reason))...")
        let context = modelContainer.mainContext
        try? await MasterSyncer(modelContext: context).pushChanges(silent: true)
        try? await VaultTaskSyncer(modelContext: context).pushChanges()
    }
}
