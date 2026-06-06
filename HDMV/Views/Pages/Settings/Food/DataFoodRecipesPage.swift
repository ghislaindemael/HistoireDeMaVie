import SwiftUI
import SwiftData

struct DataFoodRecipesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataFoodRecipesPageViewModel()
    
    @Query(filter: #Predicate<DataFoodRecipe> { $0.parentId == nil }, sort: \DataFoodRecipe.name)
    private var rootItems: [DataFoodRecipe]
    
    var body: some View {
        NavigationStack {
            GenericTreePageView(
                title: "Food Recipes",
                items: rootItems,
                childrenKeyPath: \.optionalChildren,
                isLoading: viewModel.isLoading,
                onRefresh: { await viewModel.refreshFromServer() },
                onSync: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createItem() },
                rowContent: { item in
                    DataFoodRecipeRowView(recipe: item) { it in
                        withAnimation(.snappy) {
                            it.cache.toggle()
                            it.markAsModified()
                        }
                    }

                },
                sheetContent: { item in
                    DataFoodRecipeDetailSheet(item: item, modelContext: modelContext)
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
    

}
