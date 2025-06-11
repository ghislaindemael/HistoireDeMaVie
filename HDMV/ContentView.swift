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
            HomePage()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            MealsPage()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife.circle")
                }
            AgendaPage()
                .tabItem {
                    Label("Agenda", systemImage: "pencil.and.list.clipboard")
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
