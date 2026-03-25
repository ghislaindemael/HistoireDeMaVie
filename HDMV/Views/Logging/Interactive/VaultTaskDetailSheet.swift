//
//  VaultTaskDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.03.2026.
//

import SwiftUI
import SwiftData

struct VaultTaskDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VaultTaskDetailSheetViewModel
    
    init(task: VaultTask, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: VaultTaskDetailSheetViewModel(
            model: task,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task Name", text: $viewModel.editor.name)
                        .font(.headline)
                    
                    Picker("Status", selection: $viewModel.editor.status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    Picker("Priority", selection: $viewModel.editor.priority) {
                        Text("None").tag(0)
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                }
                
                Section("Scheduling") {
                    Toggle("Has Start Date", isOn: $viewModel.editor.hasTimeStart)
                    if viewModel.editor.hasTimeStart {
                        DatePicker("Start Time", selection: Binding(
                            get: { viewModel.editor.timeStart ?? .now },
                            set: { viewModel.editor.timeStart = $0 }
                        ))
                    }
                    
                    Toggle("Has Deadline", isOn: $viewModel.editor.hasTimeEnd)
                    if viewModel.editor.hasTimeEnd {
                        DatePicker("Deadline", selection: Binding(
                            get: { viewModel.editor.timeEnd ?? .now },
                            set: { viewModel.editor.timeEnd = $0 }
                        ))
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: Binding(
                        get: { viewModel.editor.details ?? "" },
                        set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                }
                
                Section("Metadata") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(viewModel.editor.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Updated")
                        Spacer()
                        Text(viewModel.editor.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let completed = viewModel.editor.completedAt {
                        HStack {
                            Text("Completed")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: { completed },
                                set: { viewModel.editor.completedAt = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                        }
                    }
                }
                .font(.footnote)
            }
            .navigationTitle("Edit Task")
            .standardSheetToolbar(onDone: {
                viewModel.onDone()
                dismiss()
            })
        }
    }
}

@MainActor
class VaultTaskDetailSheetViewModel: BaseDetailSheetViewModel<VaultTask, VaultTaskEditor> {
}
