//
//  Permission.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//

import Foundation
import SwiftUI

enum ActivityCapability: String, Codable, CaseIterable, Identifiable {
    case create_trips
    case create_interactions
    case link_place
    case log_food
    case have_child_instances
    case be_child_instance
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
            case .create_trips: return "Can create Trips"
            case .create_interactions: return "Can create Interactions"
            case .link_place: return "Can attach Place"
            case .log_food: return "Can log Meals"
            case .have_child_instances: return "Have child instances"
            case .be_child_instance: return "Be child instance"
        }
    }
}

protocol Capable {
    var allowedCapabilities: [ActivityCapability] { get set }
    var requiredCapabilities: [ActivityCapability] { get set }
    
    func hasCapability(_ capability: ActivityCapability) -> Bool
    mutating func toggleCapability(_ capability: ActivityCapability)
    func isRequired(_ capability: ActivityCapability) -> Bool
    mutating func toggleRequired(_ capability: ActivityCapability)
    
    mutating func addRequired(_ capability: ActivityCapability)
    mutating func removeRequired(_ capability: ActivityCapability)
}

extension Capable {
    
    func can(_ capability: ActivityCapability) -> Bool {
        return hasCapability(capability)
    }
    
    func must(_ capability: ActivityCapability) -> Bool {
        return isRequired(capability)
    }
    
    func hasCapability(_ capability: ActivityCapability) -> Bool {
        return allowedCapabilities.contains(capability)
    }
    
    func isRequired(_ capability: ActivityCapability) -> Bool {
        return requiredCapabilities.contains(capability)
    }
    
    mutating func addRequired(_ capability: ActivityCapability) {
        if !isRequired(capability) {
            requiredCapabilities.append(capability)
        }
    }
    
    mutating func removeRequired(_ capability: ActivityCapability) {
        requiredCapabilities.removeAll { $0 == capability }
    }
    
    mutating func toggleCapability(_ capability: ActivityCapability) {
        if hasCapability(capability) {
            allowedCapabilities.removeAll { $0 == capability }
            removeRequired(capability)
        } else {
            allowedCapabilities.append(capability)
        }
    }
    
    mutating func toggleRequired(_ capability: ActivityCapability) {
        if isRequired(capability) {
            removeRequired(capability)
        } else {
            if hasCapability(capability) {
                addRequired(capability)
            }
        }
    }
}

extension Activity {
    
    // MARK: Named implementations
    
    func shouldShowPlaceLink(settings: SettingsStore) -> Bool {
        return must(.link_place) || (can(.link_place) && settings.planningMode)
    }
    
    func placeUnsetColor(settings: SettingsStore, placeId: Int?) -> Color {
        return linkedModelColor(capability: .link_place, modelRid: placeId, settings: settings)
    }
    
    func placeUnsetWeight(placeId: Int?) -> Font.Weight {
        return linkedModelFontWeight(capability: .link_place, modelRid: placeId)
    }
    
    
    // MARK: Base functions
    
    func linkedModelColor(capability: ActivityCapability, modelRid: Int?, settings: SettingsStore) -> Color {
        if must(capability) == true && modelRid == nil {
            return .red
        }
        else if can(capability) == true && settings.planningMode && modelRid == nil {
            return .orange
        }
        else {
            return .primary
        }
    }
    
    func linkedModelFontWeight(capability: ActivityCapability, modelRid: Int?) -> Font.Weight {
        if must(capability) == true && modelRid == nil {
            return .bold
        } else {
            return .regular
        }
    }
    
}

