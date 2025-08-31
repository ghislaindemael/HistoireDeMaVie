import SwiftUI

struct AppView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appNavigator: AppNavigator
    
    var body: some View {
        TabView(selection: $appNavigator.selectedTab) {
            
            HomePage()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)
            
            PeopleInteractionsPage()
                .tabItem { Label("Interactions", systemImage: "person.2.fill") }
                .tag(Tab.interactions)
            
            MyActivitiesPage()
                .tabItem { Label("Activities", systemImage: "flowchart") }
                .tag(Tab.activities)
            
            AgendaPage()
                .tabItem { Label("Agenda", systemImage: "pencil.and.list.clipboard") }
                .tag(Tab.agenda)
            
            SettingsPage()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }
}
