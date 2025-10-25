//
//  PeopleInteractionsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import SwiftUI
import SwiftData

struct MyInteractionsPage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    
    @StateObject private var viewModel = MyInteractionsPageViewModel()
    
    @State private var interactionToEdit: Interaction? = nil
    
    // MARK: Setup
    
    private func onAppear() {
        if let navDate = appNavigator.selectedDate {
            viewModel.filterDate = navDate
            appNavigator.selectedDate = nil
        }
        viewModel.setup(modelContext: modelContext)
        viewModel.fetchInteractions()
    }
    
    // MARK: - Filtering State
    var body: some View {
        NavigationStack {
            mainListView
                .navigationTitle("My Interactions")
                .onAppear(perform: onAppear)
                .syncingOverlay(viewModel.isLoading)
                .logPageToolbar(
                    refreshAction: { await viewModel.refreshFromServer() },
                    syncAction: { await viewModel.uploadLocalChanges() },
                    singleTapAction: { viewModel.createInteraction() },
                    longPressAction: { viewModel.createInteraction(date: viewModel.filterDate) },
                )
                .onChange(of: viewModel.filterDate) { viewModel.fetchInteractions() }
                .sheet(item: $interactionToEdit) { interaction in
                    InteractionDetailSheet(
                        interaction: interaction,
                        modelContext: modelContext
                    )
                }
        }
        .environmentObject(viewModel)
    }

    
    // MARK: - View Components
    
    private var mainListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $viewModel.filterDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.interactions) { interaction in
                        InteractionRowView(
                            interaction: interaction,
                            onEnd: {
                                viewModel.endInteraction(interaction: interaction)
                            }
                        )
                        .onTapGesture {
                            interactionToEdit = interaction
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        
    }

}


#Preview {
    let container: ModelContainer = {
        let schema = Schema([
            Person.self,
            Interaction.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            
            let matthieuC = Person(rid: 1, slug: "matthieuC", name: "Matthieu", familyName: "Colin", surname: "Brug", birthdate: nil)
            let matthieuD = Person(rid: 2, slug: "matthieuD", name: "Matthieu", familyName: "Dumont", surname: nil, birthdate: nil)
            
            context.insert(matthieuC)
            context.insert(matthieuD)
            
            let interaction1 = Interaction(
                rid: 201,
                timeStart: .now.addingTimeInterval(-1000),
                timeEnd: .now.addingTimeInterval(-720),
                percentage: 100,
                person: matthieuC,
                in_person: true,
                details: "Test",
            )
            
            let interaction2 = Interaction(
                rid: 202,
                timeStart: .now.addingTimeInterval(-1000),
                timeEnd: nil,
                percentage: 50,
                person: matthieuD,
                in_person: false,
                details: "Test",
            )
            
            context.insert(interaction1)
            context.insert(interaction2)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    
    MyInteractionsPage().modelContainer(container)
}
