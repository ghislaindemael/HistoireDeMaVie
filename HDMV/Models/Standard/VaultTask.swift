//
//  VaultTask.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.03.2026.
//

import Foundation
import SwiftData

enum TaskStatus: String, Codable, CaseIterable {
    case todo = "todo"
    case inProgress = "inProgress"
    case completed = "completed"
    case canceled = "canceled"
    
    var displayName: String {
        switch self {
            case .todo: return "To Do"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .canceled: return "Canceled"
        }
    }
}

@Model
final class VaultTask: Identifiable, SyncableModel, EditableModel {
    @Transient var id: PersistentIdentifier { persistentModelID }
    
    @Attribute(.unique) var rid: Int?
    
    var name: String
    var details: String?
    
    var statusRaw: String = TaskStatus.todo.rawValue
    var priority: Int = 0 // 0: None, 1: Low, 2: Medium, 3: High
    
    var createdAt: Date
    var updatedAt: Date
    var timeStart: Date?
    var timeEnd: Date?
    var completedAt: Date?
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = VaultTaskDTO
    typealias Payload = VaultTaskPayload
    typealias Editor = VaultTaskEditor
    
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .todo }
        set { statusRaw = newValue.rawValue }
    }
    
    init(
        rid: Int? = nil,
        name: String = "",
        details: String? = nil,
        status: TaskStatus = .todo,
        priority: Int = 0,
        timeStart: Date? = nil,
        timeEnd: Date? = nil,
        completedAt: Date? = nil,
        syncStatus: SyncStatus = .unsynced
    ) {
        let now = Date.now
        self.rid = rid
        self.name = name
        self.details = details
        self.statusRaw = status.rawValue
        self.priority = priority
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.completedAt = completedAt
        self.createdAt = now
        self.updatedAt = now
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: VaultTaskDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.details = dto.details
        self.statusRaw = dto.status
        self.priority = dto.priority
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.completedAt = dto.completed_at
        self.createdAt = dto.created_at
        self.updatedAt = dto.updated_at
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: VaultTaskDTO) {
        self.name = dto.name
        self.details = dto.details
        self.statusRaw = dto.status
        self.priority = dto.priority
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.completedAt = dto.completed_at
        self.updatedAt = dto.updated_at
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - DTO & Payload

struct VaultTaskDTO: Codable, Identifiable {
    let id: Int
    let created_at: Date
    let updated_at: Date
    let name: String
    let details: String?
    let status: String
    let priority: Int
    let time_start: Date?
    let time_end: Date?
    let completed_at: Date?
}

struct VaultTaskPayload: Codable, InitializableWithModel {
    typealias Model = VaultTask
    
    let name: String
    let details: String?
    let status: String
    let priority: Int
    let time_start: Date?
    let time_end: Date?
    let completed_at: Date?
    
    init?(from task: VaultTask) {
        guard task.isValid() else { return nil }
        self.name = task.name
        self.details = task.details
        self.status = task.statusRaw
        self.priority = task.priority
        self.time_start = task.timeStart
        self.time_end = task.timeEnd
        self.completed_at = task.completedAt
    }
}

// MARK: - Editor

struct VaultTaskEditor: EditorProtocol {
    typealias Model = VaultTask
    
    let createdAt: Date
    let updatedAt: Date
    
    var name: String
    var details: String?
    var status: TaskStatus
    var priority: Int
    var timeStart: Date?
    var timeEnd: Date?
    var completedAt: Date?
    
    var hasTimeStart: Bool
    var hasTimeEnd: Bool
    
    init(from task: VaultTask) {
        self.name = task.name
        self.details = task.details
        self.status = task.status
        self.priority = task.priority
        self.timeStart = task.timeStart
        self.timeEnd = task.timeEnd
        self.completedAt = task.completedAt
        
        self.createdAt = task.createdAt
        self.updatedAt = task.updatedAt
        
        self.hasTimeStart = task.timeStart != nil
        self.hasTimeEnd = task.timeEnd != nil
    }
    
    func apply(to task: VaultTask) {
        task.name = self.name
        task.details = self.details
        task.status = self.status
        task.priority = self.priority
        task.timeStart = self.hasTimeStart ? (self.timeStart ?? .now) : nil
        task.timeEnd = self.hasTimeEnd ? (self.timeEnd ?? .now.addingTimeInterval(3600)) : nil
        
        if self.status == .completed && task.completedAt == nil {
            task.completedAt = .now
        } else if self.status != .completed {
            task.completedAt = nil
        }
        
        task.updatedAt = .now
        task.markAsModified()
    }
}
