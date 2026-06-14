import SwiftUI
import SwiftData

struct FoodItemSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let course: CourseType?
    let onSelect: (ComposedFood) -> Void
    
    @State private var searchText = ""
    @State private var selectedTab: Int = 0 // 0: Items, 1: Recipes
    
    @Query(sort: \DataFoodItem.name) private var allItems: [DataFoodItem]
    @Query(sort: \DataFoodRecipe.name) private var allRecipes: [DataFoodRecipe]
    
    var rootItems: [DataFoodItem] {
        allItems.filter { $0.parent == nil }
    }
    
    var rootRecipes: [DataFoodRecipe] {
        allRecipes.filter { $0.parent == nil }
    }
    
    var filteredItems: [DataFoodItem] {
        allItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredRecipes: [DataFoodRecipe] {
        allRecipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Type", selection: $selectedTab) {
                    Text("Items").tag(0)
                    Text("Recipes").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    if selectedTab == 0 {
                        Button(action: {
                            addRawText(searchText.isEmpty ? "New Custom Food" : searchText)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text(searchText.isEmpty ? "Add Custom Food" : "Add \"\(searchText)\" as custom food")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        if !searchText.isEmpty {
                            ForEach(filteredItems) { item in
                                itemRow(item)
                            }
                        } else {
                            OutlineGroup(rootItems, children: \.optionalChildren) { item in
                                itemRow(item)
                            }
                        }
                    } else {
                        if !searchText.isEmpty {
                            ForEach(filteredRecipes) { recipe in
                                recipeRow(recipe)
                            }
                        } else {
                            OutlineGroup(rootRecipes, children: \.optionalChildren) { recipe in
                                recipeRow(recipe)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search Food...")
            }
            .navigationTitle(course != nil ? "Add to \(course!.rawValue)" : "Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private func itemRow(_ item: DataFoodItem) -> some View {
        Button(action: {
            addItem(item)
        }) {
            VStack(alignment: .leading) {
                Text(item.name).foregroundColor(.primary)
                if let parent = item.parent {
                    Text(parent.name).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func recipeRow(_ recipe: DataFoodRecipe) -> some View {
        Button(action: {
            applyRecipe(recipe)
        }) {
            VStack(alignment: .leading) {
                Text(recipe.name).foregroundColor(.primary)
                if let parent = recipe.parent {
                    Text(parent.name).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func addRawText(_ text: String) {
        let newFood = ComposedFood(
            foodItemRid: nil,
            rawText: text,
            course: course,
            options: nil,
            quantity: nil,
            unit: nil,
            children: nil
        )
        onSelect(newFood)
        dismiss()
    }
    
    private func addItem(_ item: DataFoodItem) {
        let newFood = ComposedFood(
            foodItemRid: item.rid,
            rawText: item.name,
            course: course,
            options: nil,
            quantity: nil,
            unit: FoodUnitType(rawValue: item.baseUnit ?? "") ?? .grams,
            children: nil
        )
        onSelect(newFood)
        dismiss()
    }
    
    private func applyRecipe(_ recipe: DataFoodRecipe) {
        if let compData = recipe.compositionRaw,
           let composition = try? JSONDecoder().decode([ComposedFood].self, from: compData) {
            
            let newFood = ComposedFood(
                foodItemRid: nil,
                rawText: recipe.name,
                course: course,
                options: nil,
                quantity: nil,
                unit: nil,
                children: composition
            )
            onSelect(newFood)
        } else {
            // Empty recipe fallback
            let newFood = ComposedFood(
                foodItemRid: nil,
                rawText: recipe.name,
                course: course,
                options: nil,
                quantity: nil,
                unit: nil,
                children: []
            )
            onSelect(newFood)
        }
        dismiss()
    }
}
