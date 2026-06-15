import SwiftUI
import SwiftData

@MainActor
class DataFoodItemsPageViewModel: ObservableObject {
    private var modelContext: ModelContext?
    @Published var isLoading: Bool = false
    private var syncer: DataFoodItemSyncer?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncer = DataFoodItemSyncer(modelContext: modelContext)
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await syncer?.pullChanges()
        } catch {
            print("Error refreshing DataFoodItem: \(error)")
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
            let predicate = #Predicate<DataFoodItem> { $0.archived == true }
            let descriptor = FetchDescriptor<DataFoodItem>(predicate: predicate)
            let archivedItems = try context.fetch(descriptor)
            
            for item in archivedItems {
                context.delete(item)
            }
            try? context.save()
        } catch {
            print("Failed to purge archived items: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await syncer?.pushChanges()
        } catch {
            print("Error uploading DataFoodItem: \(error)")
        }
    }
    
    func createItem() {
        guard let context = modelContext else { return }
        let newItem = DataFoodItem()
        context.insert(newItem)
        try? context.save()
    }
    
    func updateModel(_ model: DataFoodItem, modifier: (DataFoodItem) -> Void) {
        modifier(model)
        try? modelContext?.save()
    }
}
