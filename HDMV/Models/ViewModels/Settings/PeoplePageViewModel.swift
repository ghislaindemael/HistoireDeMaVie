//
//  PeoplePageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation
import SwiftData

@MainActor
class PeoplePageViewModel: ObservableObject {
    
    @Published var people: [Person] = []
    @Published var isLoading = false
    
    private let peopleService = PeopleService()
    
    private var modelContext: ModelContext?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        fetchFromCache()
        
        if people.isEmpty {
            Task {
                await fetchFromServer()
            }
        }
    }
    
    // MARK: - Data Loading and Caching
    
    private func fetchFromCache() {
        guard let context = modelContext else { return }
        do {
            let peopleDescriptor = FetchDescriptor<Person>(
                sortBy: [SortDescriptor(\.familyName), SortDescriptor(\.name)]
            )
            self.people = try context.fetch(peopleDescriptor)
        } catch {
            print("Failed to fetch from cache: \(error)")
        }
    }
    
    func fetchFromServer() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let peopleDTOs = try await peopleService.fetchPeople()
            
            self.people = peopleDTOs.compactMap { dto in
                Person(fromDTO: dto)
            }.sorted {
                ($0.familyName, $0.name) < ($1.familyName, $1.name)
            }
        } catch {
            print("Failed to refresh data from server: \(error)")
        }
    }
    
    
    
    // MARK: - User Actions
    
    func cachePeople() {
        guard let context = modelContext else {
            print("Cannot cache: model context is missing.")
            return
        }
        
        do {
            try context.delete(model: Person.self)
            let peopleToCache = self.people.filter { $0.cache }
            
            for person in peopleToCache {
                context.insert(person)
            }
            try context.save()
        } catch {
            print("Failed to perform targeted cache update for people: \(error)")
        }
    }
    
    func createPerson(newPerson: NewPersonPayload) async throws {
        guard let context = modelContext else { return }
        
        let createdDTO: PersonDTO = try await peopleService.createPerson(newPerson)
        
        let finalPerson = Person(fromDTO: createdDTO)
        if createdDTO.cache {
            context.insert(finalPerson)
            try context.save()
        }
    }
    
    /// Toggles the cache status for a place.
    func toggleCache(for person: Person) async {
        do {
            try await peopleService.updateCacheStatus(forPersonId: person.id, isActive: person.cache)
            try modelContext?.save()
        } catch {
            print("Failed to update cache status: \(error)")
            person.cache.toggle()
        }
    }
    
    /// Archives a person instead of deleting it.
    func archivePerson(for person: Person) {
        guard let context = modelContext else { return }
        
        people.removeAll { $0.id == person.id }
        
        Task {
            do {
                try await peopleService.archivePerson(forPersonId: person.id)
                context.delete(person)
                try context.save()
            } catch {
                print("Failed to archive place on server: \(error).")
                people.append(person)
            }
        }
    }
    
}
