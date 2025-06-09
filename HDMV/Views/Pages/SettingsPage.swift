import SwiftUI

struct SettingsPage: View {
    @ObservedObject private var auth = SupabaseService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                AuthComponent(expanded: !auth.isAuthenticated)
                
                
                
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
