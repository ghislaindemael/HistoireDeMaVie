import Foundation
import SwiftData

@MainActor
class DataBankAccountsPageViewModel: BasePageViewModel {
    
    private var syncer: DataBankAccountsSyncer?
    
    @Published var accounts: [DataBankAccount] = []
    
    // MARK: - Computed Properties for Views
    var hasLocalChanges: Bool {
        return accounts.contains(where: { $0.hasUnsyncedChanges })
    }
    
    // MARK: Initialization
    
    override func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncer = DataBankAccountsSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DataBankAccount>(
                sortBy: [SortDescriptor(\.name)]
            )
            self.accounts = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = syncer else {
            print("⚠️ [DataBankAccountsPageViewModel] Syncer is nil")
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
        executePurgeArchived(type: DataBankAccount.self, context: modelContext, fetchAction: fetchFromCache)
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = syncer else {
            print("⚠️ [DataBankAccountsPageViewModel] Syncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
}
