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
            MealType.self,
            Meal.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(HDMVApp.sharedModelContainer)
    }
}
