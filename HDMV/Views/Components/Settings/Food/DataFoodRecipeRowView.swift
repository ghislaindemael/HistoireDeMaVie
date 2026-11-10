import SwiftUI
import SwiftData

struct DataFoodRecipeRowView: View {
    let recipe: DataFoodRecipe
    let onToggleCache: (DataFoodRecipe) -> Void
    
    var body: some View {
        HStack {
            Text(recipe.name)
                .font(.headline)
            Spacer()
            CatalogueRowControlsView(model: recipe, onToggle: onToggleCache)
        }
    }
}
