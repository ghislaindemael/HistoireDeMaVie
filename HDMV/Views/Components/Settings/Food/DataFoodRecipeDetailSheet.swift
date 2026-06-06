import SwiftUI
import SwiftData

struct DataFoodRecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var item: DataFoodRecipe
    var modelContext: ModelContext
    
    @State private var editor: DataFoodRecipeEditor
    @State private var ingredients: [ComposedFood] = []
    
    @State private var showingItemSelector = false
    @State private var itemToEdit: ComposedFood? = nil
    
    @Query(sort: \DataFoodRecipe.name) private var allItems: [DataFoodRecipe]
    
    init(item: DataFoodRecipe, modelContext: ModelContext) {
        self.item = item
        self.modelContext = modelContext
        self._editor = State(initialValue: DataFoodRecipeEditor(from: item))
        
        if let raw = item.compositionRaw, let decoded = try? JSONDecoder().decode([ComposedFood].self, from: raw) {
            self._ingredients = State(initialValue: decoded)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $editor.name)
                }
                
                Section("Ingredients") {
                    ForEach(ingredients) { compItem in
                        Button {
                            itemToEdit = compItem
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(compItem.rawText ?? "Unknown Food")
                                        .foregroundColor(.primary)
                                    if let qty = compItem.quantity {
                                        Text(String(format: "%.1f", qty) + " " + (compItem.unit?.rawValue ?? ""))
                                            .font(.caption)
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
                        ingredients.remove(atOffsets: indices)
                    }
                    
                    Button("Add Ingredient") {
                        showingItemSelector = true
                    }
                }
                
                Section("Hierarchy") {
                    NavigationLink(destination: GenericTreeSelectorView(
                        items: allItems.filter { $0.parent == nil && $0.rid != item.rid },
                        childrenKeyPath: \.optionalChildren,
                        selection: $editor.parent,
                        title: "Select Parent",
                        noneButtonText: "No Parent"
                    )) {
                        HStack {
                            Text("Parent")
                            Spacer()
                            Text(editor.parent?.name ?? "None")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Usage") {
                    Toggle("Cached", isOn: $editor.cache)
                    Toggle("Archived", isOn: $editor.archived)
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                editor.apply(to: item)
                item.compositionRaw = try? JSONEncoder().encode(ingredients)
                item.markAsModified()
                try? modelContext.save()
            }
            .sheet(isPresented: $showingItemSelector) {
                FoodItemSelectorSheet(course: nil) { newFood in
                    ingredients.append(newFood)
                }
            }
            .sheet(item: $itemToEdit) { compItem in
                if let idx = ingredients.firstIndex(where: { $0.id == compItem.id }) {
                    ComposedFoodEditorSheet(item: $ingredients[idx])
                } else {
                    Text("Error: Item not found")
                }
            }
        }
    }
}
