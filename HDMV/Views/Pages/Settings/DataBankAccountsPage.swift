import SwiftUI

struct DataBankAccountsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataBankAccountsPageViewModel()
    @State private var searchText: String = ""
    
    private var filteredAccounts: [DataBankAccount] {
        guard !searchText.isEmpty else { return viewModel.accounts }
        return viewModel.accounts.filter { account in
            account.name.localizedCaseInsensitiveContains(searchText) ||
            account.currency.localizedCaseInsensitiveContains(searchText) ||
            account.accountTypeRaw.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var unsetAccounts: [DataBankAccount] {
        filteredAccounts.filter { $0.name == "Unset" || $0.name.isEmpty }
    }
    
    private var validAccounts: [DataBankAccount] {
        filteredAccounts.filter { $0.name != "Unset" && !$0.name.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !unsetAccounts.isEmpty {
                    Section("Needs Configuration / Unset") {
                        ForEach(unsetAccounts) { account in
                            accountRow(account)
                        }
                    }
                }
                
                if !validAccounts.isEmpty {
                    Section("Bank Accounts") {
                        ForEach(validAccounts) { account in
                            accountRow(account)
                        }
                    }
                } else if unsetAccounts.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("Bank Accounts")
            .searchable(text: $searchText, prompt: "Search Bank Accounts")
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
    
    @ViewBuilder
    private func accountRow(_ account: DataBankAccount) -> some View {
        DataBankAccountRowView(account: account) { acc in
            withAnimation(.snappy) {
                viewModel.updateModel(acc) { $0.cache.toggle() }
            }
        }
    }
}
