import SwiftUI
import SwiftData

struct DataFoodOptionRowView: View {
    let option: DataFoodOption
    let onToggleCache: (DataFoodOption) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(option.name)
                    .font(.headline)
                HStack {
                    Text(option.slug)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                    Text(option.typeRaw.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            CacheToggleButton(model: option, onToggle: onToggleCache)
            SyncStatusIndicator(status: option.syncStatus)
        }
    }
}
