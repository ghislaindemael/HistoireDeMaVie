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
        model.markAsModified()
        try? modelContext?.save()
    }
}
