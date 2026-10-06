import SwiftUI

struct LifeEventTypesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = LifeEventTypesPageViewModel()
    
    var body: some View {
        NavigationStack {
            GenericTreePageView(
                title: "Life Event Types",
                items: viewModel.lifeEventTypes,
                childrenKeyPath: \.optionalChildren,
                isLoading: viewModel.isLoading,
                onRefresh: { await viewModel.refreshFromServer() },
                onSync: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createLifeEventType() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() },
                rowContent: { type in
                    LifeEventTypeRowView(type: type) { t in
                        withAnimation(.snappy) {
                            viewModel.updateModel(t) { concreteType in
                                concreteType.cache.toggle()
                            }
                        }
                    }
                },
                sheetContent: { type in
                    LifeEventTypeDetailSheet(type: type, modelContext: modelContext)
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
