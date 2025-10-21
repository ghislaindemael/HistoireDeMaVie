//
//  Tab.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.09.2025.
//

import SwiftUI

/// An enum representing the main tabs of the app for type-safe navigation.
enum Tab: CaseIterable {
    case home
    case interactions
    case activities
    case agenda
    case settings
    case test
    
    var title: String {
        switch self {
            case .home: return "Home"
            case .interactions: return "Interactions"
            case .activities: return "Activities"
            case .agenda: return "Agenda"
            case .settings: return "Settings"
            case .test: return "Test"
        }
    }
    
    var icon: String {
        switch self {
            case .home: return "house.fill"
            case .interactions: return "person.2.fill"
            case .activities: return "flowchart.fill"
            case .agenda: return "calendar.and.person"
            case .settings: return "gearshape.fill"
            case .test: return "testtube.2"
        }
    }
    
    @ViewBuilder
    var page: some View {
        switch self {
            case .home:
                HomePage()
            case .interactions:
                MyInteractionsPage()
            case .activities:
                MyActivitiesPage()
            case .agenda:
                AgendaPage()
            case .settings:
                SettingsPage()
            case .test:
                TestPage()
        }
    }
}
