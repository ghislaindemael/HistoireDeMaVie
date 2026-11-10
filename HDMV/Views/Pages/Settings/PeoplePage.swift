import SwiftUI
import SwiftData

struct PeoplePage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PeoplePageViewModel()
    
    @State private var personToEdit: Person?
    @State private var searchText: String = ""
    
    private var filteredPeople: [Person] {
        guard !searchText.isEmpty else { return viewModel.people }
        return viewModel.people.filter { person in
            person.formattedName.localizedCaseInsensitiveContains(searchText) ||
            person.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var unsetPeople: [Person] {
        filteredPeople.filter { $0.name == "Unset" || $0.name.isEmpty }
    }
    
    private var validPeople: [Person] {
        filteredPeople.filter { $0.name != "Unset" && !$0.name.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !unsetPeople.isEmpty {
                    Section("Needs Configuration / Unset") {
                        ForEach(unsetPeople) { person in
                            personRow(person)
                        }
                    }
                }
                
                if !validPeople.isEmpty {
                    Section("People") {
                        ForEach(validPeople) { person in
                            personRow(person)
                        }
                    }
                } else if unsetPeople.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("People")
            .searchable(text: $searchText, prompt: "Search People")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createPerson() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
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
    private func personRow(_ person: Person) -> some View {
        Button(action: {
            personToEdit = person
        }) {
            PersonRowView(person: person) { p in
                withAnimation(.snappy) {
                    viewModel.updateModel(p) { concretePerson in
                        concretePerson.cache.toggle()
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(person)
                try? modelContext.save()
                viewModel.fetchFromCache()
            } label: {
                Label(person.syncStatus == .synced ? "Remove from Device" : "Delete", systemImage: "trash")
            }
        }
    }
}
