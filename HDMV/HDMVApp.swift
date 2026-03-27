//
//  HDMVApp.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.06.2025.
//

import SwiftUI
import SwiftData

@main
struct HDMVApp: App {
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Activity.self,
            ActivityInstance.self,
            AgendaEntry.self,
            Country.self,
            City.self,
            LifeEvent.self,
            Path.self,
            Place.self,
            Person.self,
            Interaction.self,
            Trip.self,
            Vehicle.self,
            Transaction.self,
            TransactionType.self,
            VaultTask.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject var settings = SettingsStore.shared
    @StateObject var appNavigator = AppNavigator.shared
    @StateObject private var vaultService = VaultImportService.shared

    var body: some Scene {
        WindowGroup {
                    AppView()
                        .onAppear {}
                        .onOpenURL { url in
                            vaultService.handleIncomingURL(url)
                        }
                        .sheet(isPresented: $vaultService.isShowingVaultLinker) {
                            if let fileURL = vaultService.incomingFileURL {
                                VaultLinkerSheet(fileURL: fileURL)
                            }
                        }
                        .sheet(isPresented: $vaultService.isShowingGPXImporter) {
                            if let fileURL = vaultService.incomingFileURL {
                                GPXImportSheet(fileURL: fileURL)
                            }
                        }
                }
        .modelContainer(HDMVApp.sharedModelContainer)
        .environmentObject(settings)
        .environmentObject(appNavigator)
        
    }
}
