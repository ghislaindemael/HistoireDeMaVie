import SwiftUI

struct ActivitiesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ActivitiesPageViewModel()
    
    var body: some View {
        NavigationStack {
            GenericTreePageView(
                title: "Activities",
                items: viewModel.activities,
                childrenKeyPath: \.optionalChildren,
                isLoading: viewModel.isLoading,
                onRefresh: { await viewModel.refreshFromServer() },
                onSync: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createActivity() },
                rowContent: { activity in
                    ActivityRowView(activity: activity) { act in
                        withAnimation(.snappy) {
                            viewModel.updateModel(act) { concreteAct in
                                concreteAct.cache.toggle()
                            }
                        }
                    }
                },
                sheetContent: { activity in
                    ActivityDetailSheet(activity: activity, modelContext: modelContext)
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
