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
    var contextRids: [Int] = []
    var linkedFilePaths: [String] = []
    var log_details: Data?
    @Attribute var syncStatusRaw: String = SyncStatus.unsynced.rawValue
    
    var decodedLogDetails: LogDetails? {
        get {
            guard let data = log_details else { return nil }
            return try? JSONDecoder().decode(LogDetails.self, from: data)
        }
        set {
            var details = newValue
            details?.cleanEmptyOptions()
            log_details = try? JSONEncoder().encode(details)
        }
    }
        
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
        contextRids: [Int] = [],
        linkedFilePaths: [String] = [],
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.date = date ?? Self.dateFormatter.string(from: .now)
        self.daySummary = daySummary
        self.contextRids = contextRids
        self.linkedFilePaths = linkedFilePaths
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: AgendaEntryDTO) {
        self.init()
        self.rid = dto.id
        self.date = dto.date
        self.daySummary = dto.day_summary ?? ""
        self.contextRids = dto.context_ids ?? []
        self.linkedFilePaths = dto.linked_file_paths ?? []
        self.decodedLogDetails = dto.log_details
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: AgendaEntryDTO) {
        self.daySummary = dto.day_summary ?? ""
        self.contextRids = dto.context_ids ?? []
        self.linkedFilePaths = dto.linked_file_paths ?? []
        self.decodedLogDetails = dto.log_details
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return !daySummary.isEmpty
            || !(decodedLogDetails?.options?.isEmpty ?? true)
            || !contextRids.isEmpty
            || !linkedFilePaths.isEmpty
    }
}

struct AgendaEntryDTO: Codable, Sendable, Identifiable {
    var id: Int
    var date: String
    var day_summary: String?
    var context_ids: [Int]?
    var linked_file_paths: [String]?
    var log_details: LogDetails?
}

struct AgendaEntryPayload: Codable, InitializableWithModel {
    typealias Model = AgendaEntry
    
    let id: Int
    let date: String
    let day_summary: String
    let context_ids: [Int]
    let linked_file_paths: [String]
    let log_details: LogDetails?
    
    init?(from entry: AgendaEntry) {
        guard entry.isValid(), let rid = entry.rid else { return nil }
        
        self.id = rid
        self.date = entry.date
        self.day_summary = entry.daySummary
        self.context_ids = entry.contextRids
        self.linked_file_paths = entry.linkedFilePaths
        
        if var details = entry.decodedLogDetails {
            details.removeFields()
            self.log_details = details
        } else {
            self.log_details = nil
        }
    }
}

struct AgendaEntryEditor: EditorProtocol {
    typealias Model = AgendaEntry
    
    var daySummary: String
    var contextRids: [Int] = []
    var linkedFilePaths: [String] = []
    var log_details: LogDetails?
    
    init(from entry: AgendaEntry) {
        self.daySummary = entry.daySummary
        self.contextRids = entry.contextRids
        self.linkedFilePaths = entry.linkedFilePaths
        self.log_details = entry.decodedLogDetails
    }
    
    func apply(to entry: AgendaEntry) {
        entry.daySummary = self.daySummary
        entry.contextRids = self.contextRids
        entry.linkedFilePaths = self.linkedFilePaths
        entry.decodedLogDetails = self.log_details
        entry.markAsModified()
    }
}

