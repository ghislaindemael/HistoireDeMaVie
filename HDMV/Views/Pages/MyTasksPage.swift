//
//  MyTasksPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.03.2026.
//

import SwiftUI
import SwiftData

struct MyTasksPage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    
    @StateObject private var viewModel = MyTasksPageViewModel()
    @State private var taskToEdit: VaultTask?
    
    private func onAppear() {
        viewModel.setup(modelContext: modelContext)
        viewModel.fetchTasks()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: Filter Picker
                Picker("Filter", selection: $viewModel.filterMode) {
                    ForEach(MyTasksPageViewModel.FilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(uiColor: .systemBackground))
                
                // MARK: List
                List {
                    if viewModel.tasks.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "No Tasks",
                            systemImage: "checklist",
                            description: Text(viewModel.filterMode == .completed ? "You haven't completed any tasks yet." : "You're all caught up!")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.tasks, id: \.persistentModelID) { task in
                            TaskRowView(task: task) {
                                viewModel.toggleCompletion(for: task)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                taskToEdit = task
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("My Tasks")
            .onAppear(perform: onAppear)
            .syncingOverlay(viewModel.isLoading)
            .logPageToolbar(
                refreshAction: { await viewModel.syncWithServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: {
                    viewModel.createTask()
                }
            )
            .onChange(of: viewModel.filterMode) {
                viewModel.fetchTasks()
            }
            .sheet(item: $taskToEdit, onDismiss: { viewModel.fetchTasks() }) { task in
                VaultTaskDetailSheet(
                    task: task,
                    modelContext: modelContext
                )
            }
        }
        .environmentObject(viewModel)
    }
}
