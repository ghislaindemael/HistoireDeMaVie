import SwiftUI
import SwiftData

struct DataMediaItemSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedItem: DataMediaItem?
    
    @Query(FetchDescriptor<DataMediaItem>(
        sortBy: [SortDescriptor(\.name)]))
    private var items: [DataMediaItem]
    
        
    var body: some View {
        GenericTreeSelectorView(
            items: items,
            childrenKeyPath: \.optionalChildren,
            selection: $selectedItem,
            title: "Select Media Item",
            noneButtonText: "None"
        )
    }
}
