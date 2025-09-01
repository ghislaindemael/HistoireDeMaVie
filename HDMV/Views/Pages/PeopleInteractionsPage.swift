//
//  PeopleInteractionsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import SwiftUI
import SwiftData

struct PeopleInteractionsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PeopleInteractionsPageViewModel()
    
    @State private var interactionToEdit: PersonInteraction? = nil
    @State private var deletingInteraction: PersonInteraction? = nil
    
    // MARK: - Filtering State
    @State private var selectedPersonId: Int? = nil
    @State private var showUnassigned: Bool = true
    @State private var isFilteringExpanded: Bool = false
        
    private var filteredInteractions: [PersonInteraction] {
        viewModel.interactions.filter { interaction in
            let isAssigned = interaction.person_id > 0
            
            if isAssigned {
                return selectedPersonId == nil || interaction.person_id == selectedPersonId
            }
            return showUnassigned
        }
    }
    
    var body: some View {
        NavigationStack {
            interactionsListView
                .navigationTitle("People Interactions")
                .logPageToolbar(
                    refreshAction: { await viewModel.syncWithServer() },
                    hasLocalChanges: viewModel.hasLocalChanges,
                    syncAction: { await viewModel.syncChanges() },
                    singleTapAction: { viewModel.createNewInteractionInCache() },
                    longPressAction: { viewModel.createNewInteractionAtNoonInCache() },
                )
                .task(id: viewModel.selectedDate) {
                    await viewModel.syncWithServer()
                }
                .onAppear {
                    viewModel.setup(modelContext: modelContext)
                }
                .overlay {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .sheet(item: $interactionToEdit) { interaction in
                    PersonInteractionEditSheet(
                        interaction: interaction,
                        viewModel: viewModel
                    )
                }
        }
        .alert("Delete Interaction?", isPresented: .constant(deletingInteraction != nil), presenting: deletingInteraction) { interaction in
            Button("Delete", role: .destructive) {
                deleteInteraction(interaction)
                deletingInteraction = nil
            }
            Button("Cancel", role: .cancel) {
                deletingInteraction = nil
            }
        } message: { interaction in
            Text("Are you sure you want to delete this interaction with \(viewModel.people.first(where: { $0.id == interaction.person_id })?.fullName ?? "Unknown")?")
        }
        
    }
    
    // MARK: - View Components
    
    private var interactionsListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            filteringControls
            List {
                ForEach(filteredInteractions) { interaction in
                    viewForRow(for: interaction )
                }
                .onDelete(perform: delete)
                
            }
        }
        
    }
    
    @ViewBuilder
    private var filteringControls: some View {
        DisclosureGroup("Filtering", isExpanded: $isFilteringExpanded) {
            HStack(spacing: 16) {
                Picker("Person", selection: $selectedPersonId) {
                    Text("All People").tag(Int?.none)
                    ForEach(viewModel.people) { person in
                        Text(person.fullName).tag(person.id as Int?)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                Text("Unassigned")
                Toggle("Unassigned", isOn: $showUnassigned)
                    .labelsHidden()
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
    
    private func viewForRow(for interaction: PersonInteraction) -> some View {
        VStack(spacing: 8) {
            PersonInteractionRowView(
                interaction: interaction,
                person: viewModel.people.first(where: { $0.id == interaction.person_id })
            )
            .contentShape(Rectangle())
            .onTapGesture {
                interactionToEdit = interaction
            }
            if interaction.time_end == nil {
                EndItemButton(title: "End Interaction") {
                    viewModel.endPersonInteraction(interaction: interaction)
                }
            }
        }
    }
    
    private func deleteInteraction(_ interaction: PersonInteraction) {
        viewModel.deleteInteraction(interaction)
    }
    
    private func delete(at offsets: IndexSet) {
        if let first = offsets.first {
            deletingInteraction = filteredInteractions[first]
        }
    }
}


#Preview {
    let container: ModelContainer = {
        let schema = Schema([
            Person.self,
            PersonInteraction.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            
            let matthieuC = Person(id: 1, slug: "matthieuC", name: "Matthieu", familyName: "Colin", surname: "Brug", birthdate: nil, cache: true)
            let matthieuD = Person(id: 2, slug: "matthieuD", name: "Matthieu", familyName: "Dumont", surname: nil, birthdate: nil, cache: true)
            
            context.insert(matthieuC)
            context.insert(matthieuD)
            
            let interaction1 = PersonInteraction(
                id: 201,
                time_start: .now.addingTimeInterval(-1000),
                time_end: .now.addingTimeInterval(-720),
                person_id: 1,
                in_person: true,
                details: "Test",
                percentage: 100
            )
            
            let interaction2 = PersonInteraction(
                id: 202,
                time_start: .now.addingTimeInterval(-1000),
                time_end: nil,
                person_id: 2,
                in_person: false,
                details: "Test",
                percentage: 50
            )
            
            context.insert(interaction1)
            context.insert(interaction2)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    
    PeopleInteractionsPage().modelContainer(container)
}
