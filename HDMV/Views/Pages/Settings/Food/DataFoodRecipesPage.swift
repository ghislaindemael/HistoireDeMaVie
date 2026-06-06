import SwiftUI
import SwiftData

struct DataFoodRecipesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataFoodRecipesPageViewModel()
    
    @Query(FetchDescriptor<DataFoodRecipe>(sortBy: [SortDescriptor(\.name)]))
    private var items: [DataFoodRecipe]
    
    @State private var itemToEdit: DataFoodRecipe?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    Button(action: { itemToEdit = item }) {
                        HStack {
                            Text(item.name)
                            Spacer()
                            SyncStatusIndicator(status: item.syncStatus)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Food Recipes")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createItem() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $itemToEdit) { item in
                DataFoodRecipeDetailSheet(item: item, modelContext: modelContext)
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}
