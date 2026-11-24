import SwiftUI

struct SettingsPage: View {
    @ObservedObject private var auth = SupabaseService.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    var body: some View {
        NavigationStack {
            ScrollView{
                LazyVStack {
                    AuthComponent(expanded: !auth.isAuthenticated)
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Auto-Push Changes", isOn: $settings.autoPushEnabled)
                            .font(.headline)
                        Text("Automatically upload pending local changes when leaving the app or reconnecting.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                    )
                    DataManagementComponent()
                    ConfigPageLinksComponent()
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsPage()
}
