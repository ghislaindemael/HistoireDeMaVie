import SwiftUI
import SwiftData

struct DataFoodOptionsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataFoodOptionsPageViewModel()
    
    @Query(FetchDescriptor<DataFoodOption>(sortBy: [SortDescriptor(\.name)]))
    private var items: [DataFoodOption]
    
    @State private var itemToEdit: DataFoodOption?
    
    private var unsetItems: [DataFoodOption] {
        items.filter { $0.name.isUnset() || $0.slug.isUnset() }
    }
    
    private var validItems: [DataFoodOption] {
        items.filter { $0.name.isNotUnset() && $0.slug.isNotUnset() }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !unsetItems.isEmpty {
                    Section("Needs Configuration / Unset") {
                        ForEach(unsetItems) { item in
                            optionRow(item)
                        }
                        .onDelete { offsets in
                            deleteItems(from: unsetItems, at: offsets)
                        }
                    }
                }
                
                Section {
                    ForEach(validItems) { item in
                        optionRow(item)
                    }
                    .onDelete { offsets in
                        deleteItems(from: validItems, at: offsets)
                    }
                }
            }
            .navigationTitle("Food Options")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createItem() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $itemToEdit) { item in
                DataFoodOptionDetailSheet(item: item, modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private func optionRow(_ item: DataFoodOption) -> some View {
        Button(action: { itemToEdit = item }) {
            HStack {
                Text(item.name)
                    .bold(item.name.isUnset())
                    .foregroundStyle(item.name.isUnset() ? .red : .primary)
                Spacer()
                SyncStatusIndicator(status: item.syncStatus)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func deleteItems(from list: [DataFoodOption], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(list[index])
        }
        try? modelContext.save()
    }
}
