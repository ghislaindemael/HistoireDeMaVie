import SwiftUI
import SwiftData

@MainActor
class DataFoodOptionsPageViewModel: BasePageViewModel {
    var syncer: AnySyncer?
    var sortDescriptors: [SortDescriptor<DataFoodOption>] = [SortDescriptor(\.name)]
    
    override func setup(modelContext: ModelContext) {
        super.setup(modelContext: modelContext)
        self.syncer = DataFoodOptionSyncer(modelContext: modelContext)
    }
    
    func refreshFromServer() async {
        _ = await super.refreshFromServer(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func uploadLocalChanges() async {
        _ = await super.uploadLocalChanges(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func fetchArchivedFromServer() async {
        _ = await super.fetchArchivedFromServer(syncer: syncer, sortDescriptors: sortDescriptors)
    }
    
    func purgeArchivedFromCache() {
        _ = super.purgeArchivedFromCache(sortDescriptors: sortDescriptors)
    }
    
    func createItem() {
        _ = super.createPlaceholderIfNeeded(
            factory: { DataFoodOption(syncStatus: .unsynced) },
            sortDescriptors: sortDescriptors
        )
    }
}
