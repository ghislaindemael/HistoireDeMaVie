//
//  LifeEventType.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//

import Foundation
import SwiftData

enum LifeEventType: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    
    case accident
    case activity
    case blunder
    case decision
    case discovery
    case emotion
    case failure
    case health
    case loss
    case meet
    case milestone
    case reflection
    case reward
    case search
    case social
    case stress
    case success
    case transition
    case unset
    
    var name: String {
        switch self {
            case .accident: return "Accident"
            case .activity: return "Activity"
            case .blunder: return "Blunder"
            case .decision: return "Decision"
            case .discovery: return "Discovery"
            case .emotion: return "Emotion"
            case .failure: return "Failure"
            case .health: return "Health"
            case .loss: return "Loss"
            case .meet: return "Meet"
            case .milestone: return "Milestone"
            case .reflection: return "Reflection"
            case .reward: return "Reward"
            case .search: return "Search"
            case .social: return "Social"
            case .stress: return "Stress"
            case .success: return "Success"
            case .transition: return "Transition"
            case .unset: return "Unset"
        }
    }
    
    var icon: String {
        switch self {
            case .accident: return "⚠️"
            case .activity: return "🛠️"
            case .blunder: return "questionmark.circle.fill"
            case .decision: return "🧭"
            case .discovery: return "🔍"
            case .emotion: return "♥️"
            case .failure: return "💔"
            case .health: return "💊"
            case .loss: return "💔"
            case .meet: return "🤝"
            case .milestone: return "🎯"
            case .reflection: return "💭"
            case .reward: return "💰"
            case .search: return "🔍"
            case .social: return "👥"
            case .stress: return "♥️"
            case .success: return "🏆"
            case .transition: return "🔄"
            case .unset: return "questionmark.circle"

        }
    }
    
    var label: String {
        "\(icon) \(name)"
    }
}

