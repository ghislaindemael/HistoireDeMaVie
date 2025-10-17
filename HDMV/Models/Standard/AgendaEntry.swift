//
//  Agenda.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//


import Foundation
import SwiftData

// The SwiftData Model for storing an agenda entry locally
@Model
final class AgendaEntry: Identifiable {
    @Attribute(.unique) var date: String
    var daySummary: String
    var mood: Int
    var moodComments: String
    
    // Memberwise initializer
    init(date: String, daySummary: String = "", mood: Int = 5, moodComments: String = "") {
        self.date = date
        self.daySummary = daySummary
        self.mood = mood
        self.moodComments = moodComments
    }
}

// The DTO for transferring agenda data to/from Supabase
struct AgendaDTO: Codable, Sendable {
    var date: String
    var day_summary: String
    var mood: Int
    var mood_comments: String
}
