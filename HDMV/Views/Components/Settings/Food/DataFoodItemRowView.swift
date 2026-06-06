import SwiftUI
import SwiftData

struct DataFoodItemRowView: View {
    let item: DataFoodItem
    let onToggleCache: (DataFoodItem) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                if let unit = item.baseUnit {
                    Text("Base Unit: \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            CacheToggleButton(model: item, onToggle: onToggleCache)
            SyncStatusIndicator(status: item.syncStatus)
        }
    }
}
