//
//  DataFoodRecipeDetailSheetViewModel.swift
//  HDMV
//

import SwiftUI
import SwiftData

@MainActor
class DataFoodRecipeDetailSheetViewModel: BaseDetailSheetViewModel<DataFoodRecipe, DataFoodRecipeEditor> {
    @Published var ingredients: [ComposedFood] = []
    
    override init(model: DataFoodRecipe, modelContext: ModelContext) {
        super.init(model: model, modelContext: modelContext)
        if let raw = model.compositionRaw, let decoded = try? JSONDecoder().decode([ComposedFood].self, from: raw) {
            self.ingredients = decoded
        }
    }
    
    override func onDone() {
        model.compositionRaw = try? JSONEncoder().encode(ingredients)
        super.onDone()
    }
}
