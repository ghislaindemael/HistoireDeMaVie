//
//  MyAgendaPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//


import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class MyAgendaPageViewModel: ObservableObject {

    @Published var agendaEntry: AgendaEntry?
    @Published var lifeEvents: [LifeEvent] = []
    
    @Published var filterDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .undef
    @Published var isNewEntry: Bool = false
    
    private var modelContext: ModelContext?
    private var agendaSyncer: AgendaEntrySyncer?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.agendaSyncer = AgendaEntrySyncer(modelContext: modelContext)
        fetchDailyData()
    }
    
    func fetchDailyData() {
        self.agendaEntry = fetchLocalAgenda(for: filterDate)
        // TODO: Pull lifevents
    }
    
    private func fetchLocalAgenda(for date: Date) -> AgendaEntry? {
        guard let context = modelContext else { return nil }
        let dateString = ISO8601DateFormatter.justDate.string(from: date)
        let predicate = #Predicate<AgendaEntry> { $0.date == dateString }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        return try? context.fetch(descriptor).first
    }
    
    func createAgendaEntry() {
        guard let context = modelContext else { return }
        
        if fetchLocalAgenda(for: filterDate) != nil {
            print("Agenda entry already exists for this date.")
            return
        }
        
        print("Creating new local agenda entry for \(filterDate).")
        let dateString = ISO8601DateFormatter.justDate.string(from: filterDate)
        let dayNumber = DayCalculator.dayNumber(for: filterDate)
        
        let newEntry = AgendaEntry(
            rid: dayNumber,
            date: dateString,
            syncStatus: SyncStatus.local
        )
        
        context.insert(newEntry)
        do {
            try context.save()
            self.agendaEntry = newEntry
        } catch {
            print("Failed to create new AgendaEntry: \(error)")
        }
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        try? await agendaSyncer?.pullChanges(date: filterDate)
        fetchDailyData()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        try? await agendaSyncer?.pushChanges()
        fetchDailyData()
    }
    
    func createLifeEvent() {
        print("Create Life Event tapped (not implemented)")
    }
    
}
