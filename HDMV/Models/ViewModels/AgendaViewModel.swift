//
//  AgendaViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//


import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class AgendaViewModel: ObservableObject {
    // UI-bound properties
    @Published var daySummary: String = ""
    @Published var moodComments: String = ""
    @Published var mood: Double = 5.0
    
    // Page state
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .undefined
    @Published var isNewEntry: Bool = false
    
    private let agendaService = AgendaService()
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.modelContext = HDMVApp.sharedModelContainer.mainContext

        Publishers.CombineLatest3($daySummary, $moodComments, $mood)
            .dropFirst()
            .sink { [weak self] _, _, _ in
                if self?.syncStatus == .synced {
                    self?.syncStatus = .local
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchAgendaForSelectedDate() async {
        isLoading = true
        errorMessage = nil
        
        if let localAgenda = try? fetchLocalAgenda(for: selectedDate) {
            self.daySummary = localAgenda.daySummary
            self.moodComments = localAgenda.moodComments
            self.mood = Double(localAgenda.mood)
            self.isNewEntry = false
            self.syncStatus = .local
            self.isLoading = false
            return
        }
        
        syncStatus = .syncing
        do {
            if let agendaData = try await agendaService.fetchAgenda(for: selectedDate) {
                self.daySummary = agendaData.day_summary
                self.moodComments = agendaData.mood_comments
                self.mood = Double(agendaData.mood)
                self.isNewEntry = false
                self.syncStatus = .synced
            } else {
                resetFields()
                self.isNewEntry = true
                self.syncStatus = .local
            }
        } catch {
            self.errorMessage = "Error fetching agenda: \(error.localizedDescription)"
            self.syncStatus = .failed
        }
        
        isLoading = false
    }
    
    func saveChanges() {
        syncStatus = .syncing
        errorMessage = nil
        
        let agendaDto = AgendaDTO(
            date: ISO8601DateFormatter.justDate.string(from: selectedDate),
            day_summary: self.daySummary,
            mood: Int(self.mood),
            mood_comments: self.moodComments
        )
        
        Task {
            do {
                if self.isNewEntry {
                    _ = try await agendaService.insertAgenda(agendaDto)
                } else {
                    try await agendaService.updateAgenda(agendaDto)
                }
                
                if let localAgenda = try? self.fetchLocalAgenda(for: self.selectedDate) {
                    self.modelContext.delete(localAgenda)
                    try self.modelContext.save()
                }
                
                self.syncStatus = .synced
                self.isNewEntry = false
                
            } catch {
                // --- FAILURE: SAVE WORK TO LOCAL DB ---
                self.saveToLocalDatabase()
                self.syncStatus = .failed
                self.errorMessage = "Offline. Saved locally."
            }
        }
    }
    
    private func saveToLocalDatabase() {
        if let existingLocalAgenda = try? fetchLocalAgenda(for: selectedDate) {
            existingLocalAgenda.daySummary = self.daySummary
            existingLocalAgenda.mood = Int(self.mood)
            existingLocalAgenda.moodComments = self.moodComments
        } else {
            let newLocalAgenda = AgendaEntry(
                date: ISO8601DateFormatter.justDate.string(from: selectedDate),
                daySummary: self.daySummary,
                mood: Int(self.mood),
                moodComments: self.moodComments
            )
            modelContext.insert(newLocalAgenda)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save agenda to local database: \(error)")
        }
    }
    
    /// Fetches a single agenda entry from the local SwiftData store.
    private func fetchLocalAgenda(for date: Date) throws -> AgendaEntry? {
        let dateString = ISO8601DateFormatter.justDate.string(from: date)
        let predicate = #Predicate<AgendaEntry> { $0.date == dateString }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date)])
        return try modelContext.fetch(descriptor).first
    }

    private func resetFields() {
        self.daySummary = ""
        self.moodComments = ""
        self.mood = 5.0
    }
}
