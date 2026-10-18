import SwiftUI
import SwiftData

struct DataFoodItemRowView: View {
    let item: DataFoodItem
    let onToggleCache: (DataFoodItem) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                if let details = item.details, !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let unit = item.baseUnit {
                    Text("Base Unit: \(unit)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            CacheToggleButton(model: item, onToggle: onToggleCache)
            SyncStatusIndicator(status: item.syncStatus)
        }
    }
}
