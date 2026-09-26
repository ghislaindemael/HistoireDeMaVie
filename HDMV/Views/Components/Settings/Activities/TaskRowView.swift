//
//  TaskRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.03.2026.
//

import SwiftUI
import SwiftData

struct TaskRowView: View {
    let task: VaultTask
    var showToggle: Bool = true
    let onToggle: () -> Void
    
    private var priorityColor: Color {
        switch task.priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .gray
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        if task.status == .completed {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        } else if task.status == .canceled {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "circle")
                .font(.title2)
                .foregroundStyle(priorityColor)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // MARK: - Checkbox Button
            if showToggle {
                Button(action: onToggle) {
                    statusIcon
                }
                .buttonStyle(.plain)
            } else {
                statusIcon
            }
            
            // MARK: - Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name.isEmpty ? "New Task" : task.name)
                    .font(.headline)
                    .strikethrough(task.status == .completed || task.status == .canceled, color: .secondary)
                    .foregroundStyle(task.status == .completed || task.status == .canceled ? .secondary : .primary)
                
                if let deadline = task.timeEnd, task.status == .todo || task.status == .inProgress {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.exclamationmark")
                        Text(deadline.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundStyle(deadline < .now ? .red : .secondary) 
                } else if let completed = task.completedAt, task.status == .completed {
                    Text("Done \(completed.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let canceled = task.canceledAt, task.status == .canceled {
                    Text("Canceled \(canceled.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // MARK: - Sync Status (Optional, matches your other rows)
            SyncStatusIndicator(status: task.syncStatus)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primaryBackground)
        )
    }
}

func toggleTask(_ task: VaultTask) {
    if task.status == .completed {
        task.status = .todo
        task.completedAt = nil
    } else {
        task.status = .completed
        task.completedAt = .now
    }
    task.updatedAt = .now
    task.markAsModified()
}
