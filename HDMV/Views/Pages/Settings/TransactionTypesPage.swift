import SwiftUI

struct TransactionTypesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TransactionTypesPageViewModel()
    
    var body: some View {
        NavigationStack {
            GenericTreePageView(
                title: "Transaction Types",
                items: viewModel.transactionTypes,
                childrenKeyPath: \.optionalChildren,
                isLoading: viewModel.isLoading,
                onRefresh: { await viewModel.refreshFromServer() },
                onSync: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createTransactionType() },
                rowContent: { type in
                    TransactionTypeRowView(type: type) { t in
                        withAnimation(.snappy) {
                            viewModel.updateModel(t) { concreteType in
                                concreteType.cache.toggle()
                            }
                        }
                    }
                },
                sheetContent: { type in
                    TransactionTypeDetailSheet(type: type, modelContext: modelContext)
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
