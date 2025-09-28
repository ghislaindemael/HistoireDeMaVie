//
//  AppNavigator.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.08.2025.
//

import SwiftUI

/// A shared object to coordinate navigation between different parts of the app.
class AppNavigator: ObservableObject {
    /// The currently selected tab. The TabView will be bound to this.
    @Published var selectedTab: Tab = .home
    
    /// An optional date used to navigate to a specific day in a feature view.
    @Published var selectedDate: Date? = nil
}
