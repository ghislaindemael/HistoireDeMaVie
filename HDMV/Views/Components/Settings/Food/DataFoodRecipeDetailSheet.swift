import SwiftUI
import SwiftData

struct DataFoodRecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var item: DataFoodRecipe
    var modelContext: ModelContext
    
    @StateObject var viewModel: DataFoodRecipeDetailSheetViewModel
    
    @State private var showingItemSelector = false
    @State private var itemToEdit: ComposedFood? = nil
    
    @Query(sort: \DataFoodRecipe.name) private var allItems: [DataFoodRecipe]
    
    init(item: DataFoodRecipe, modelContext: ModelContext) {
        self.item = item
        self.modelContext = modelContext
        self._viewModel = StateObject(wrappedValue: DataFoodRecipeDetailSheetViewModel(model: item, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $viewModel.editor.name)
                }
                
                Section("Ingredients") {
                    ForEach(viewModel.ingredients) { compItem in
                        Button {
                            itemToEdit = compItem
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(compItem.rawText ?? "Unknown Food")
                                        .foregroundColor(.primary)
                                    if let details = compItem.details, !details.isEmpty {
                                        Text(details)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    if let qty = compItem.quantity {
                                        let unitStr = compItem.unit?.rawValue ?? ""
                                        Text("\(qty, specifier: "%.1f") \(unitStr)")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .imageScale(.small)
                            }
                        }
                    }
                    .onDelete { indices in
                        viewModel.ingredients.remove(atOffsets: indices)
                    }
                    
                    Button("Add Ingredient") {
                        showingItemSelector = true
                    }
                }
                
                Section("Hierarchy") {
                    NavigationLink(destination: GenericTreeSelectorView(
                        items: allItems.filter { $0.parent == nil && $0.rid != item.rid },
                        childrenKeyPath: \.optionalChildren,
                        selection: $viewModel.editor.parent,
                        title: "Select Parent",
                        noneButtonText: "No Parent"
                    )) {
                        HStack {
                            Text("Parent")
                            Spacer()
                            Text(viewModel.editor.parent?.name ?? "None")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                UsageSectionView(isCached: $viewModel.editor.cache, isArchived: $viewModel.editor.archived)
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
            .sheet(isPresented: $showingItemSelector) {
                FoodItemSelectorSheet(course: nil) { newItem in
                    viewModel.ingredients.append(newItem)
                }
            }
            .sheet(item: $itemToEdit) { compItem in
                if let index = viewModel.ingredients.firstIndex(where: { $0.id == compItem.id }) {
                    ComposedFoodEditorSheet(item: $viewModel.ingredients[index])
                }
            }
        }
    }
}
