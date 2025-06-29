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
    
    @Query private var people: [Person]
    
    @State private var editingInteraction: PersonInteraction? = nil
    
    @State private var endingInteractionId: Int?
    
    public init() {}
    
    
    var body: some View {
        NavigationStack {
            interactionsListView
                .navigationTitle("Interactions")
                .toolbar { toolbarContent }
                .task(id: viewModel.selectedDate) {
                    await viewModel.loadData()
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
                .sheet(item: $editingInteraction) { interaction in
                    EditInteractionSheet(
                        people: people,
                        interaction: interaction,
                        onSave: { updated in
                            viewModel.updateInteraction(updated)
                            editingInteraction = nil
                        }
                    )
                }

        }
    }
    
    // MARK: - View Components
    
    /// A computed property for the main view content to help the compiler.
    private var interactionsListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
            List {
                ForEach(viewModel.allInteractions) { interaction in
                    viewForRow(for: interaction )
                }
            }
        }
        
    }
    
    private func viewForRow(for interaction: PersonInteraction) -> some View {
        VStack(spacing: 8) {
            PersonInteractionRowView(
                interaction: interaction,
                person: people.first(where: { $0.id == interaction.person_id })
            )
            .padding(.top, interaction.time_end == nil ? 6 : 0)
            .animation(nil, value: endingInteractionId)
            .zIndex(1)
            
            endInteractionButton(for: interaction)
                .frame(maxHeight: interaction.time_end == nil ? .infinity : 0)
                .opacity(interaction.time_end == nil ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: interaction.time_end)
                .scaleEffect(endingInteractionId == interaction.id ? 0.01 : 1.0)
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    editingInteraction = interaction
                }
        )
        .onLongPressGesture {
            editingInteraction = interaction
        }
    }
    
    @ViewBuilder
    private func endInteractionButton(for interaction: PersonInteraction) -> some View {
        
        Button("End Interaction") {
            withAnimation {
                endingInteractionId = interaction.id
            } completion: {
                let ended = interaction
                ended.time_end = .now
                viewModel.updateInteraction(ended)
                endingInteractionId = nil
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .buttonStyle(.plain)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                Task { await viewModel.loadData() }
            }) {
                Image(systemName: "icloud.and.arrow.down")
                Text("Refresh")
            }
            .accessibilityLabel("Reload trips")
        }
        
        if viewModel.hasLocalInteractions {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    Task { await viewModel.syncChanges() }
                }) {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Save")
                }
                .accessibilityLabel("Sync changes")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                let new = PersonInteraction(
                    id: viewModel.generateTempID(),
                    date: viewModel.selectedDate,
                    time_start: .now,
                    time_end: nil,
                    person_id: 0,
                    in_person: true,
                    details: nil,
                    percentage: 100,
                    syncStatus: SyncStatus.local
                )
                editingInteraction = new
            }) {
                Label("New", systemImage: "plus")
            }
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
            
            let matthieuC = Person(
                id: 1,
                slug: "matthieuC",
                name: "Matthieu",
                familyName: "Colin",
                surname: "Brug",
                birthdate: nil,
                cache: true
            )
            
            let matthieuD = Person(
                id: 2,
                slug: "matthieuD",
                name: "Matthieu",
                familyName: "Dumont",
                surname: nil,
                birthdate: nil,
                cache: true
            )

            context.insert(matthieuC)
            context.insert(matthieuD)
            
            
            let interaction1 = PersonInteraction(
                id: 201,
                date: .now,
                time_start: .now.addingTimeInterval(-1000),
                time_end: .now.addingTimeInterval(-720),
                person_id: 1,
                in_person: true,
                details: "Test",
                percentage: 100,
            )
            
            let interaction2 = PersonInteraction(
                id: 202,
                date: .now,
                time_start: .now.addingTimeInterval(-1000),
                time_end: nil,
                person_id: 2,
                in_person: false,
                details: "Test",
                percentage: 50,
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

