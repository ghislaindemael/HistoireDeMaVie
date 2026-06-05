import SwiftUI
import SwiftData

struct DataMediaItemSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedItem: DataMediaItem?
    
    @Query(FetchDescriptor<DataMediaItem>(
        sortBy: [SortDescriptor(\.name)]))
    private var items: [DataMediaItem]
    
        
    var body: some View {
        Picker("Select Media Item", selection: $selectedItem) {
            Text("None").tag(nil as DataMediaItem?)
            ForEach(items) { item in
                Text(item.name).tag(item as DataMediaItem)
            }
        }
        .pickerStyle(.menu)
    }
}
