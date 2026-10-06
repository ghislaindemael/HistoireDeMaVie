import Foundation
import SwiftData

@MainActor
class LifeEventTypesPageViewModel: BasePageViewModel {
    
    private var lifeEventTypesSyncer: LifeEventTypesSyncer?
    
    @Published var lifeEventTypes: [LifeEventType] = []
    
    // MARK: - Computed Properties for Views
    var hasLocalChanges: Bool {
        return lifeEventTypes.contains(where: { $0.hasUnsyncedChanges })
    }
    
    // MARK: Initialization
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lifeEventTypesSyncer = LifeEventTypesSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let predicate = #Predicate<LifeEventType> { $0.parent == nil }
            
            let descriptor = FetchDescriptor<LifeEventType>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.name)]
            )
            
            self.lifeEventTypes = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = lifeEventTypesSyncer else {
            print("⚠️ [LifeEventTypesPageViewModel] Syncer is nil")
            return
        }
        do {
            try await syncer.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func fetchArchivedFromServer() async {
        await executeFetchArchived(refreshAction: refreshFromServer)
    }
    
    func purgeArchivedFromCache() {
        executePurgeArchived(type: LifeEventType.self, context: modelContext, fetchAction: fetchFromCache)
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = lifeEventTypesSyncer else {
            print("⚠️ [LifeEventTypesPageViewModel] Syncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    
    // MARK: User Actions
    
    func createLifeEventType() {
        guard let context = modelContext else { return }
        let newType = LifeEventType(name: "New Type", slug: "new_type", syncStatus: .unsynced)
        
        context.insert(newType)
        lifeEventTypes.append(newType)
        do {
            try context.save()
        } catch {
            print("Failed to create LifeEvent Type: \(error)")
        }
    }
    
}
