//
//  MyAgendaPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//


import SwiftUI

struct MyAgendaPage: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var settings: SettingsStore
    
    @StateObject private var viewModel = MyAgendaPageViewModel()
    
    @State private var entryToEdit: AgendaEntry?
    @State private var eventToEdit: LifeEvent?
    @State private var quoteToEdit: Quote?
    
    // MARK: Setup
    
    private func onAppear() {
        if let navDate = appNavigator.selectedDate {
            viewModel.filterDate = navDate
            if settings.planningMode == false {
                appNavigator.selectedDate = nil
            }
        }
        viewModel.setup(modelContext: modelContext)
        viewModel.fetchDailyData()
    }
    
    var body: some View {
        NavigationStack {
            mainListView
                .navigationTitle("My Agenda")
                .logPageToolbar(
                    refreshAction: { await viewModel.refreshFromServer() },
                    syncAction: { await viewModel.uploadLocalChanges() },
                    onAdd: { viewModel.createLifeEvent() },
                    trailingOptions: {
                        Section("Create New") {
                            Button(action: { viewModel.createAgendaEntry() }) {
                                Label("Agenda Entry", systemImage: "book.pages")
                            }
                            Button(action: { viewModel.createQuote() }) {
                                Label("Quote", systemImage: "quote.bubble")
                            }
                        }
                    }
                )
                .syncingOverlay(viewModel.isLoading)
                .onAppear(perform: onAppear)
                .onChange(of: viewModel.filterDate) {
                    viewModel.fetchDailyData()
                }
                .sheet(item: $entryToEdit, onDismiss: { viewModel.fetchDailyData() }) { entry in
                    AgendaEntryDetailSheet(entry: entry, modelContext: modelContext)
                }
                .sheet(item: $eventToEdit) { event in
                    LifeEventDetailSheet(lifeEvent: event, modelContext: modelContext)
                }
                .sheet(item: $quoteToEdit) { quote in
                    QuoteDetailSheet(quote: quote, modelContext: modelContext)
                }
        }
        
        
    }
    
    private var mainListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $viewModel.filterDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
            if let entry = viewModel.agendaEntry {
                AgendaEntryRowView(entry: entry)
                    .padding(.horizontal)
                    .onTapGesture {
                        entryToEdit = entry
                    }
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.combinedItems) { item in
                        switch item {
                        case .lifeEvent(let event):
                            LifeEventRowView(
                                event: event,
                                selectedDate: viewModel.filterDate
                            )
                            .onTapGesture {
                                eventToEdit = event
                            }
                        case .quote(let quote):
                            QuoteRowView(quote: quote)
                                .onTapGesture {
                                    quoteToEdit = quote
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        
    }
    
}

#Preview {
    MyAgendaPage()
    
}
