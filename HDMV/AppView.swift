//
//  ContentView.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.06.2025.
//

import SwiftUI

struct AppView: View {
    var body: some View {
        TabView() {
            Tab ("Home", systemImage: "house.fill") {
                HomePage()
            }
            
            Tab ("Interactions", systemImage: "person.2.fill") {
                PeopleInteractionsPage()
            }
            
            Tab ("Trips", systemImage: "car.fill") {
                TripsPage()
            }
            
            Tab("Meals", systemImage: "fork.knife.circle") {
                MealsPage()
            }
            
            Tab ("Agenda", systemImage: "pencil.and.list.clipboard"){
                AgendaPage()
            }
            
            Tab ("Settings", systemImage: "gearshape") {
                SettingsPage()
            }
        }
    }
}



#Preview {
    AppView()
}
