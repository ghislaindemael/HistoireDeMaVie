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
    @Published var quotes: [Quote] = []
    
    var combinedItems: [AgendaLogItem] {
        let events = lifeEvents.map { AgendaLogItem.lifeEvent($0) }
        let qs = quotes.map { AgendaLogItem.quote($0) }
        return (events + qs).sorted { $0.timeStart > $1.timeStart }
    }
    
    @Published var filterDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .undef
    @Published var isNewEntry: Bool = false
    
    private var modelContext: ModelContext?
    private var agendaSyncer: AgendaEntrySyncer?
    private var lifeEventSyncer: LifeEventSyncer?
    private var quoteSyncer: QuoteSyncer?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.agendaSyncer = AgendaEntrySyncer(modelContext: modelContext)
        self.lifeEventSyncer = LifeEventSyncer(modelContext: modelContext)
        self.quoteSyncer = QuoteSyncer(modelContext: modelContext)
        fetchDailyData()
    }
    
    func fetchDailyData() {
        self.agendaEntry = fetchLocalAgenda(for: filterDate)
        fetchLifeEvents()
        fetchQuotes()
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
            print("Error during life event fetch: \(error)")
            self.lifeEvents = []
        }
    }
    
    private func fetchQuotes() {
        guard let context = modelContext else { return }
        
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: filterDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let predicate = #Predicate<Quote> {
                $0.timeStart >= startOfDay && $0.timeStart < endOfDay
            }
            let descriptor = FetchDescriptor<Quote>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
            )
            self.quotes = try context.fetch(descriptor)
        } catch {
            print("Error during quote fetch: \(error)")
            self.quotes = []
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
        try? await quoteSyncer?.pullChanges(date: filterDate)
        fetchDailyData()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        try? await agendaSyncer?.pushChanges()
        try? await lifeEventSyncer?.pushChanges()
        try? await quoteSyncer?.pushChanges()
        fetchDailyData()
    }
    
    func createLifeEvent() {
        guard let context = modelContext else { return }
        let newEvent = LifeEvent.create(in: context, date: filterDate)
        self.lifeEvents.append(newEvent)
        fetchDailyData() // Will sort them via combinedItems
    }
    
    func createQuote() {
        guard let context = modelContext else { return }
        let newQuote = Quote.create(in: context, date: filterDate)
        self.quotes.append(newQuote)
        fetchDailyData()
    }
}

enum AgendaLogItem: Identifiable {
    case lifeEvent(LifeEvent)
    case quote(Quote)
    
    var id: String {
        switch self {
        case .lifeEvent(let e): return "event_\(e.id)"
        case .quote(let q): return "quote_\(q.id)"
        }
    }
    
    var timeStart: Date {
        switch self {
        case .lifeEvent(let e): return e.timeStart
        case .quote(let q): return q.timeStart
        }
    }
}
