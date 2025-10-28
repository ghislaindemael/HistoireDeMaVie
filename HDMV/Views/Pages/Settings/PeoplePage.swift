import SwiftUI
import SwiftData

struct PeoplePage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PeoplePageViewModel()
    
    @State private var personToEdit: Person?
    
    var body: some View {
        NavigationStack {
            Form {
                peopleList
            }
            .navigationTitle("People")
            .logPageToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                singleTapAction: { viewModel.createPerson() },
                longPressAction: {}
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $personToEdit) { person in
                PersonDetailSheet(person: person, modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private var peopleList: some View {
        Section("People") {
            ForEach(viewModel.people) { person in
                Button(action: {
                    personToEdit = person
                }) {
                    PersonRowView(person: person)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
