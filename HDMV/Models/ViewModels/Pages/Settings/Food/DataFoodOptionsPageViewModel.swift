import SwiftUI
import SwiftData

@MainActor
class DataFoodOptionsPageViewModel: ObservableObject {
    private var modelContext: ModelContext?
    @Published var isLoading: Bool = false
    private var syncer: DataFoodOptionSyncer?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncer = DataFoodOptionSyncer(modelContext: modelContext)
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await syncer?.pullChanges()
        } catch {
            print("Error refreshing DataFoodOption: \(error)")
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
            let predicate = #Predicate<DataFoodOption> { $0.archived == true }
            let descriptor = FetchDescriptor<DataFoodOption>(predicate: predicate)
            let archivedItems = try context.fetch(descriptor)
            
            for item in archivedItems {
                context.delete(item)
            }
            try? context.save()
        } catch {
            print("Failed to purge archived options: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await syncer?.pushChanges()
        } catch {
            print("Error uploading DataFoodOption: \(error)")
        }
    }
    
    func createItem() {
        guard let context = modelContext else { return }
        let newItem = DataFoodOption()
        context.insert(newItem)
        try? context.save()
    }
    
    func updateModel(_ model: DataFoodOption, modifier: (DataFoodOption) -> Void) {
        modifier(model)
        try? modelContext?.save()
    }
}
