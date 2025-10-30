//
//  AgendaEntry.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//


import Foundation
import SwiftData

@Model
final class AgendaEntry: LogModel {
    
    @Attribute(.unique) var date: String
    @Attribute(.unique) var rid: Int?
    var daySummary: String = ""
    var mood: Int = 5
    var moodComments: String = ""
    @Attribute var syncStatusRaw: String = SyncStatus.local.rawValue
        
    var timeStart: Date {
        get {
            return Self.dateFormatter.date(from: self.date) ?? Calendar.current.startOfDay(for: .now)
        }
        set {
            self.date = Self.dateFormatter.string(from: newValue)
        }
    }
    
    var timeEnd: Date? {
        get {
            let startDate = self.timeStart
            return Calendar.current.date(byAdding: .day, value: 1, to: startDate)
        }
        set {
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    typealias Payload = AgendaEntryPayload
    typealias DTO = AgendaEntryDTO
    typealias Editor = AgendaEntryEditor
    
    init(
        rid: Int? = nil,
        date: String? = dateFormatter.string(from: .now),
        daySummary: String = "",
        mood: Int = 5,
        moodComments: String = "",
        syncStatus: SyncStatus = .local
    ) {
        self.rid = rid
        self.date = date ?? Self.dateFormatter.string(from: .now)
        self.daySummary = daySummary
        self.mood = mood
        self.moodComments = moodComments
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: AgendaEntryDTO) {
        self.init()
        self.rid = dto.id
        self.date = dto.date
        self.daySummary = dto.day_summary
        self.mood = dto.mood
        self.moodComments = dto.mood_comments
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: AgendaEntryDTO) {
        self.daySummary = dto.day_summary
        self.mood = dto.mood
        self.moodComments = dto.mood_comments
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return !daySummary.isEmpty
    }
}

struct AgendaEntryDTO: Codable, Sendable, Identifiable {
    var id: Int
    var date: String
    var day_summary: String
    var mood: Int
    var mood_comments: String
}

struct AgendaEntryPayload: Codable, InitializableWithModel {
    typealias Model = AgendaEntry
    
    let id: Int
    let date: String
    let day_summary: String
    let mood: Int
    let mood_comments: String
    
    init?(from entry: AgendaEntry) {
        guard entry.isValid(), let rid = entry.rid else { return nil }
        
        self.id = rid
        self.date = entry.date
        self.day_summary = entry.daySummary
        self.mood = entry.mood
        self.mood_comments = entry.moodComments
    }
}

struct AgendaEntryEditor: EditorProtocol {
    typealias Model = AgendaEntry
    
    var daySummary: String
    var mood: Int
    var moodComments: String
    
    init(from entry: AgendaEntry) {
        self.daySummary = entry.daySummary
        self.mood = entry.mood
        self.moodComments = entry.moodComments
    }
    
    func apply(to entry: AgendaEntry) {
        entry.daySummary = self.daySummary
        entry.mood = self.mood
        entry.moodComments = self.moodComments
    }
}

