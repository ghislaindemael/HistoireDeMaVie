import SwiftUI
import SwiftData

struct PeoplePage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PeoplePageViewModel()
    
    @State private var isShowingCreateSheet = false
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.refreshDataFromServer()
                        }
                    }) {
                        Image(systemName: "icloud.and.arrow.down.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingCreateSheet.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            viewModel.setup(modelContext: modelContext)
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            NewPersonSheet(viewModel: viewModel)
        }
    }
}
