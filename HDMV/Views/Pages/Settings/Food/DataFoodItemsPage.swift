import SwiftUI
import SwiftData

struct DataFoodItemsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataFoodItemsPageViewModel()
    
    @Query(filter: #Predicate<DataFoodItem> { $0.parent == nil }, sort: \DataFoodItem.name)
    private var rootItems: [DataFoodItem]
    
    var body: some View {
        NavigationStack {
            GenericTreePageView(
                title: "Food Items",
                items: rootItems,
                childrenKeyPath: \.optionalChildren,
                isLoading: viewModel.isLoading,
                onRefresh: { await viewModel.refreshFromServer() },
                onSync: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createItem() },
                rowContent: { item in
                    DataFoodItemRowView(item: item) { it in
                        withAnimation(.snappy) {
                            it.cache.toggle()
                            it.markAsModified()
                        }
                    }

                },
                sheetContent: { item in
                    DataFoodItemDetailSheet(item: item, modelContext: modelContext)
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
    

}
