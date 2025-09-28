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
            Path.self,
            Place.self,
            Person.self,
            PersonInteraction.self,
            TripLeg.self,
            Vehicle.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject var settings = SettingsStore()
    @StateObject var appNavigator = AppNavigator()

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(HDMVApp.sharedModelContainer)
        .environmentObject(settings)
        .environmentObject(appNavigator)
    }
}
