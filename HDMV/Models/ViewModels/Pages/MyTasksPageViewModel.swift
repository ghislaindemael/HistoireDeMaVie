//
//  MyTasksPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.03.2026.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class MyTasksPageViewModel: ObservableObject {
    
    enum FilterMode: String, CaseIterable {
        case pending = "Pending"
        case completed = "Completed"
        case all = "All"
    }
    
    private var modelContext: ModelContext?
    private var taskSyncer: VaultTaskSyncer?
    
    @Published var isLoading: Bool = false
    @Published var filterMode: FilterMode = .pending
    @Published var tasks: [VaultTask] = []
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.taskSyncer = VaultTaskSyncer(modelContext: modelContext)
    }
    
    // MARK: - Data Fetching
    
    func fetchTasks() {
        guard let context = modelContext else { return }
        
        do {
            // Fetch all tasks, sorted by Priority (High to Low), then by newest creation
            let descriptor = FetchDescriptor<VaultTask>(
                sortBy: [
                    SortDescriptor(\.priority, order: .reverse),
                    SortDescriptor(\.createdAt, order: .reverse)
                ]
            )
            
            let allTasks = try context.fetch(descriptor)
            
            switch filterMode {
            case .pending:
                self.tasks = allTasks.filter { $0.status == .todo || $0.status == .inProgress }
            case .completed:
                self.tasks = allTasks.filter { $0.status == .completed }
            case .all:
                self.tasks = allTasks
            }
        } catch {
            print("Error fetching tasks: \(error)")
            self.tasks = []
        }
    }
    
    // MARK: - Core Synchronization Logic
    
    func syncWithServer() async {
        isLoading = true
        defer { isLoading = false }
        try? await taskSyncer?.pullChanges()
        fetchTasks()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        try? await taskSyncer?.pushChanges()
        fetchTasks()
    }
    
    // MARK: - User Actions
    
    func createTask() {
        guard let context = modelContext else { return }
        let newTask = VaultTask(name: "")
        context.insert(newTask)
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            print("Failed to create task: \(error)")
        }
    }
    
    func toggleCompletion(for task: VaultTask) {
        guard let context = modelContext else { return }
        
        if task.status == .completed {
            task.status = .todo
            task.completedAt = nil
        } else {
            task.status = .completed
            task.completedAt = .now
        }
        
        task.updatedAt = .now
        task.markAsModified()
        
        try? context.save()
        fetchTasks()
    }
    
    func deleteTask(_ task: VaultTask) {
        guard let context = modelContext else { return }
        
        if task.rid == nil {
            context.delete(task)
        } else {
            //task.syncStatusRaw = SyncStatus.deleted.rawValue
        }
        
        try? context.save()
        fetchTasks()
    }
}
