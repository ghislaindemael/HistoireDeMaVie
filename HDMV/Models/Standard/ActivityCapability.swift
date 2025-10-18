//
//  Permission.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//


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

extension Activity {
    
    func can(_ capability: ActivityCapability) -> Bool {
        return allowedCapabilities.contains(capability)
    }
    
    func must(_ capability: ActivityCapability) -> Bool {
        return requiredCapabilities.contains(capability)
    }
    
    func hasCapability(_ capability: ActivityCapability) -> Bool {
        return allowedCapabilities.contains(capability)
    }
    
    func toggleCapability(_ capability: ActivityCapability) {
        if hasCapability(capability) {
            allowedCapabilities.removeAll { $0 == capability }
            removeRequired(capability)
        } else {
            allowedCapabilities.append(capability)
        }
    }
    
    /// Checks if a capability is marked as required.
    func isRequired(_ capability: ActivityCapability) -> Bool {
        return requiredCapabilities.contains(capability)
    }
    
    /// Adds a capability to the required list.
    private func addRequired(_ capability: ActivityCapability) {
        if !isRequired(capability) {
            requiredCapabilities.append(capability)
        }
    }
    
    /// Removes a capability from the required list.
    private func removeRequired(_ capability: ActivityCapability) {
        requiredCapabilities.removeAll { $0 == capability }
    }
    
    /// Toggles a capability's required status.
    func toggleRequired(_ capability: ActivityCapability) {
        if isRequired(capability) {
            removeRequired(capability)
        } else {
            if hasCapability(capability) {
                addRequired(capability)
            }
        }
    }
}
