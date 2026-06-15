import SwiftUI
import SwiftData

@MainActor
class DataFoodRecipesPageViewModel: ObservableObject {
    private var modelContext: ModelContext?
    @Published var isLoading: Bool = false
    private var syncer: DataFoodRecipeSyncer?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncer = DataFoodRecipeSyncer(modelContext: modelContext)
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await syncer?.pullChanges()
        } catch {
            print("Error refreshing DataFoodRecipe: \(error)")
        }
    }
    
    func fetchArchivedFromServer() async {
        SettingsStore.shared.includeArchived = true
        defer { SettingsStore.shared.includeArchived = false }
        
        await refreshFromServer()
    }
    
    func purgeArchivedFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let predicate = #Predicate<DataFoodRecipe> { $0.archived == true }
            let descriptor = FetchDescriptor<DataFoodRecipe>(predicate: predicate)
            let archivedItems = try context.fetch(descriptor)
            
            for item in archivedItems {
                context.delete(item)
            }
            try? context.save()
        } catch {
            print("Failed to purge archived recipes: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await syncer?.pushChanges()
        } catch {
            print("Error uploading DataFoodRecipe: \(error)")
        }
    }
    
    func createItem() {
        guard let context = modelContext else { return }
        let newItem = DataFoodRecipe()
        context.insert(newItem)
        try? context.save()
    }
    
    func updateModel(_ model: DataFoodRecipe, modifier: (DataFoodRecipe) -> Void) {
        modifier(model)
        try? modelContext?.save()
    }
}
