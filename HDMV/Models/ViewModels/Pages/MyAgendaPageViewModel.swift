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
    private var lifeEventSyncer: LifeEventSyncer?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.agendaSyncer = AgendaEntrySyncer(modelContext: modelContext)
        self.lifeEventSyncer = LifeEventSyncer(modelContext: modelContext)
        fetchDailyData()
    }
    
    func fetchDailyData() {
        self.agendaEntry = fetchLocalAgenda(for: filterDate)
        fetchLifeEvents()
    }
    
    private func fetchLocalAgenda(for date: Date) -> AgendaEntry? {
        guard let context = modelContext else { return nil }
        let dateString = ISO8601DateFormatter.justDate.string(from: date)
        let predicate = #Predicate<AgendaEntry> { $0.date == dateString }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        return try? context.fetch(descriptor).first
    }
    
    private func fetchLifeEvents() {
        guard let context = modelContext else { return }
        
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: filterDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let predicate = #Predicate<LifeEvent> {
                $0.timeStart >= startOfDay && $0.timeStart < endOfDay
            }
            let descriptor = FetchDescriptor<LifeEvent>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
            )
            self.lifeEvents = try context.fetch(descriptor)
        } catch {
            print("Error during interaction fetch: \(error)")
            self.lifeEvents = []
        }
    }
    
    // MARK: - Creation Logic
    
    func createAgendaEntry() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            if fetchLocalAgenda(for: filterDate) != nil {
                print("Agenda entry already exists locally.")
                return
            }
            
            do {
                try await agendaSyncer?.pullChanges(date: filterDate)
            } catch {
                print("⚠️ Warning: Could not check server for existing agenda (\(error)). Creating locally anyway.")
            }
            
            if let downloadedEntry = fetchLocalAgenda(for: filterDate) {
                print("Agenda entry found on server and downloaded.")
                self.agendaEntry = downloadedEntry
                return
            }
            
            guard let context = modelContext else { return }
            
            print("Creating new local agenda entry for \(filterDate).")
            let dateString = ISO8601DateFormatter.justDate.string(from: filterDate)
            let dayNumber = DayCalculator.dayNumber(for: filterDate)
            
            let newEntry = AgendaEntry(
                rid: dayNumber,
                date: dateString,
                syncStatus: SyncStatus.unsynced
            )
            
            context.insert(newEntry)
            do {
                try context.save()
                self.agendaEntry = newEntry
            } catch {
                print("Failed to create new AgendaEntry: \(error)")
            }
        }
    }
    
    // MARK: - Sync Logic
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        try? await agendaSyncer?.pullChanges(date: filterDate)
        try? await lifeEventSyncer?.pullChanges(date: filterDate)
        fetchDailyData()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        try? await agendaSyncer?.pushChanges()
        try? await lifeEventSyncer?.pushChanges()
        fetchDailyData()
    }
    
    func createLifeEvent() {
        guard let context = modelContext else { return }
        
        let date = filterDate.smartCreationTime
        
        let newEvent = LifeEvent(
            timeStart: date
        )
        context.insert(newEvent)
        do {
            try context.save()
            self.lifeEvents.append(newEvent)
            self.lifeEvents.sort { $0.timeStart > $1.timeStart }
        } catch {
            print("Failed to create lifeEvent: \(error)")
        }
    }
}
