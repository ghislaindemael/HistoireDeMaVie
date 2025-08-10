import SwiftUI
import SwiftData

struct PeoplePage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PeoplePageViewModel()
    
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("People")) {
                    ForEach(viewModel.people) { person in
                        HStack {
                            Text(person.fullName)
                            Spacer()
                            Toggle(isOn: Binding<Bool>(
                                get: { person.cache },
                                set: { newValue in
                                    person.cache = newValue
                                    Task {
                                        await viewModel.toggleCache(for: person)
                                    }
                                }
                            )) {
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .navigationTitle("People")
            .standardConfigPageToolbar(
                refreshAction: viewModel.fetchFromServer,
                cacheAction: viewModel.cachePeople,
                isShowingAddSheet: $isShowingAddSheet
            )
        }
        .task {
            viewModel.setup(modelContext: modelContext)
        }
        .sheet(isPresented: $isShowingAddSheet) {
            NewPersonSheet(viewModel: viewModel)
        }
    }
}
