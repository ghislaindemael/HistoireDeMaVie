import SwiftUI

struct LifeEventTypeRowView: View {
    
    let type: LifeEventType
    let onCacheToggle: (LifeEventType) -> Void
    
    var body: some View {
        HStack {
            IconView(iconString: type.icon ?? "")
            Text(type.name)
            Spacer()
            CacheToggleButton(model: type) { t in
                onCacheToggle(t)
            }
            SyncStatusIndicator(status: type.syncStatus)
        }
        .foregroundStyle(.primary)
    }
}
