//
//  ContentView.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.06.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MealsPage()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife.circle")
                }
            SettingsPage()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        
        }
    }
}

#Preview {
    ContentView()
}
