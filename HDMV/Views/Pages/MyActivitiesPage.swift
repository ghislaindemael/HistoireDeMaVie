//
//  MyActivitiesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct MyActivitiesPage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var settings: SettingsStore
    
    @StateObject private var viewModel = MyActivitiesPageViewModel()
    
    @State private var instanceToEdit: ActivityInstance?
    @State private var tripToEdit: Trip?
    @State private var interactionToEdit: Interaction?
    @State private var transactionToEdit: Transaction?
    @State private var lifeEventToEdit: LifeEvent?
    @State private var quoteToEdit: Quote?
    @State private var showingImporter = false
    
    private func onAppear() {
        if let navDate = appNavigator.selectedDate {
            viewModel.filterDate = navDate
            if settings.appMode == .live {
                appNavigator.selectedDate = nil
            }
        }
        viewModel.setup(modelContext: modelContext)
        viewModel.fetchDailyData()
    }
    
    // MARK: - Main Body (Kept lightweight for the compiler)
    var body: some View {
        NavigationStack {
            mainListView
                .onAppear(perform: onAppear)
                .syncingOverlay(viewModel.isLoading)
                .logPageToolbar(
                    refreshAction: { await viewModel.syncWithServer() },
                    syncAction: { await viewModel.uploadLocalChanges() },
                    onAdd: { viewModel.createActivityInstance() },
                    showTrailingOptions: viewModel.filterMode == .daily,
                    leadingOptions: {
                        Section("Integrations") {
                            Button(action: { showingImporter = true }) {
                                Label("Apple Health", systemImage: "heart.text.square.fill")
                            }
                        }
                    }
                ) {
                    Section("Create New") {
                        Button(action: { viewModel.createParentAndChildActivity() }) {
                            Label("Parent + Child", systemImage: "arrow.down.right.square")
                        }
                        Button(action: { viewModel.createLifeEvent() }) {
                            Label("Life Event", systemImage: "star.fill")
                        }
                        Button(action: { viewModel.createQuote() }) {
                            Label("Quote", systemImage: "quote.bubble.fill")
                        }
                    }
                }
        }
        .environmentObject(viewModel)
    }
    
    // MARK: - View Components (Sheets & Observers attached here to split compile time)
    private var mainListView: some View {
        VStack(spacing: 12) {
            GenericFilterControlView(
                filterMode: $viewModel.filterMode,
                filterDate: $viewModel.filterDate,
                filterStartDate: $viewModel.filterStartDate,
                filterEndDate: $viewModel.filterEndDate,
                advancedFilterLabel: "Activity"
            ) {
                NavigationLink {
                    ActivitySelectorView(selectedActivity: $viewModel.filterActivity)
                } label: {
                    Text(viewModel.filterActivity?.name ?? "Select one")
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.timelineItems, id: \.id) { item in
                        if let instance = item as? ActivityInstance {
                            ParentModelHierarchyView(
                                parent: instance,
                                level: 0,
                                instanceToEdit: $instanceToEdit,
                                tripToEdit: $tripToEdit,
                                interactionToEdit: $interactionToEdit,
                                lifeEventToEdit: $lifeEventToEdit,
                                quoteToEdit: $quoteToEdit
                            )
                        } else if let lifeEvent = item as? LifeEvent {
                            LifeEventRowView(event: lifeEvent, selectedDate: viewModel.filterDate)
                                .onTapGesture(count: 2) {
                                    lifeEventToEdit = lifeEvent
                                }
                                .draggable(DraggableLogItem.lifeEvent(lifeEvent.persistentModelID))
                        } else if let quote = item as? Quote {
                            QuoteRowView(quote: quote)
                                .onTapGesture(count: 2) {
                                    quoteToEdit = quote
                                }
                                .draggable(DraggableLogItem.quote(quote.persistentModelID))
                        }
                    }
                }
            }
            .padding(8)
            .id(viewModel.scrollResetID)
        }
        .navigationTitle("My Activities")
        .onChange(of: viewModel.filterMode) { viewModel.fetchDailyData() }
        .onChange(of: viewModel.filterDate) {
            viewModel.fetchDailyData()
            appNavigator.selectedDate = viewModel.filterDate
        }
        
        .sheet(item: $instanceToEdit, onDismiss: { viewModel.fetchDailyData() }) { instance in
            ActivityInstanceDetailSheet(
                instance: instance,
                modelContext: modelContext
            )
        }
        .sheet(item: $tripToEdit) { trip in
            TripDetailSheet(
                trip: trip,
                modelContext: modelContext
            )
        }
        .sheet(item: $interactionToEdit) { interaction in
            InteractionDetailSheet(
                interaction: interaction,
                modelContext: modelContext
            )
        }
        .sheet(item: $transactionToEdit) { transaction in
            TransactionDetailSheet(
                transaction: transaction,
                modelContext: modelContext
            )
        }
        .sheet(item: $lifeEventToEdit, onDismiss: { viewModel.fetchDailyData() }) { lifeEvent in
            LifeEventDetailSheet(
                lifeEvent: lifeEvent,
                modelContext: modelContext
            )
        }
        .sheet(item: $quoteToEdit, onDismiss: { viewModel.fetchDailyData() }) { quote in
            QuoteDetailSheet(
                quote: quote,
                modelContext: modelContext
            )
        }
        .sheet(isPresented: $showingImporter) {
            WorkoutImportSheet(modelContext: modelContext)
        }
    }
}
