import SwiftUI

struct DataBankAccountsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataBankAccountsPageViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("") {
                    ForEach(viewModel.accounts) { account in
                        DataBankAccountRowView(account: account) { acc in
                            withAnimation(.snappy) {
                                viewModel.updateModel(acc) { $0.cache.toggle() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bank Accounts")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
