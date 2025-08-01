import SwiftUI

struct SettingsPage: View {
    @ObservedObject private var auth = SupabaseService.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                AuthComponent(expanded: !auth.isAuthenticated)
                DataManagementComponent()
                ConfigPageLinksComponent()
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsPage()
}
