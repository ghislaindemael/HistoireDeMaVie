//
//  PeoplePageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation
import SwiftData

@MainActor
class PeoplePageViewModel: BasePageViewModel {
    
    private var personSyncer: PersonSyncer?
    
    @Published var people: [Person] = []
    
    
    // MARK: Init
    
    override func setup(modelContext: ModelContext) {
        super.setup(modelContext: modelContext)
        self.personSyncer = PersonSyncer(modelContext: modelContext)
        fetchFromCache()
    }
    
    // MARK: - Data Loading and Caching
    
    func fetchFromCache() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\.familyName), SortDescriptor(\.name)])
        self.people = (try? context.fetch(descriptor)) ?? []
    }
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = personSyncer else {
            print("⚠️ [PeoplePageViewModel] Syncer is nil")
            return
        }
        do {
            try await syncer.pullChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        guard let syncer = personSyncer else {
            print("⚠️ [PeoplePageViewModel] countriesSyncer is nil")
            return
        }
        do {
            _ = try await syncer.pushChanges()
            fetchFromCache()
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    // MARK: - User Actions

    
    func createPerson() {
        guard let context = modelContext else { return }
        let newPerson = Person(
            slug: "unset",
            name: "Unset",
            familyName: "Unset",
            syncStatus: .unsynced)
        context.insert(newPerson)
        do {
            try context.save()
        } catch {
            print("Failed to create Person: \(error)")
        }
        
    }
    
    
}
