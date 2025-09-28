import SwiftUI

struct AppView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appNavigator: AppNavigator
    
    var body: some View {
        VStack(spacing: 0) {
            appNavigator.selectedTab.page
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            SlidingTabBar(selectedTab: $appNavigator.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}
