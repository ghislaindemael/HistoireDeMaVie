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
                    singleTapAction: { viewModel.createLifeEvent() },
                    longPressAction: { viewModel.createAgendaEntry() }
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
                    ForEach(viewModel.lifeEvents) { event in
                        LifeEventRowView(
                            event: event,
                            selectedDate: viewModel.filterDate
                        )
                        .onTapGesture {
                            eventToEdit = event
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
