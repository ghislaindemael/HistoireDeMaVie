//
//  ParentModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.11.2025.
//

import Foundation

enum ChildrenDisplayMode: String, CaseIterable, Codable {
    case all
    case ongoing
    case none
}

protocol ParentModel: LogModel {
    
    var childActivities: [ActivityInstance]? { get set }
    var childTrips: [Trip]? { get set }
    var childInteractions: [Interaction]? { get set }
    var childLifeEvents: [LifeEvent]? { get set }
    
    var childrenDisplayModeRaw: String { get set }
    
}

extension ParentModel {
    
    func hasChildren() -> Bool {
        return !(self.childActivities?.isEmpty ?? true) ||
        !(self.childTrips?.isEmpty ?? true) ||
        !(self.childInteractions?.isEmpty ?? true) ||
        !(self.childLifeEvents?.isEmpty ?? true)
    }
    
    func hasActiveChild() -> Bool {
        return hasActiveTrips() || hasActiveInteractions() || hasActiveInteractions()
    }
    
    func hasActiveTrips() -> Bool {
        childTrips?.contains { $0.timeEnd == nil } ?? false
    }
    
    func hasActiveInteractions() -> Bool {
        childInteractions?.contains { $0.timeEnd == nil } ?? false
    }
    
    func hasActiveActivities() -> Bool {
        childActivities?.contains { $0.timeEnd == nil } ?? false
    }
    
    var sortedChildren: [any LogModel] {
        var allChildren: [any LogModel] = []
        
        if let childActivities = self.childActivities {
            allChildren.append(contentsOf: childActivities)
        }
        if let trips = self.childTrips {
            allChildren.append(contentsOf: trips)
        }
        if let interactions = self.childInteractions {
            allChildren.append(contentsOf: interactions)
        }
        if let lifeEvents = self.childLifeEvents {
            allChildren.append(contentsOf: lifeEvents)
        }
        return allChildren.sorted(by: { $0.timeStart < $1.timeStart })
    }
    
    var invalidChildren: [any LogModel] {
        guard let parentEndTime = self.timeEnd else {
            return []
        }
        
        let parentStartTime = self.timeStart
        
        return self.sortedChildren.filter { item in
            let startsAfterParentEnds = item.timeStart >= parentEndTime
            let endsBeforeParentStarts = (item.timeEnd ?? Date.distantFuture) <= parentStartTime
            
            return startsAfterParentEnds || endsBeforeParentStarts
        }
    }
    
    func children(overlapping date: Date?) -> [any LogModel] {
        let allChildren = self.sortedChildren
        
        guard let filterDate = date else {
            return allChildren
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: filterDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        let future = Date.distantFuture
        
        return allChildren.filter { item in
            item.timeStart < endOfDay && (item.timeEnd ?? future) > startOfDay
        }
    }
    
    func advanceDisplayMode() {
        let all = ChildrenDisplayMode.allCases
        
        guard let currentIndex = all.firstIndex(of: childrenDisplayMode) else {
            childrenDisplayMode = all.first ?? .all
            return
        }
        
        let nextIndex = all.index(after: currentIndex)
        
        if nextIndex == all.endIndex {
            childrenDisplayMode = all.first!
        } else {
            childrenDisplayMode = all[nextIndex]
        }
    }
    
    var childrenDisplayMode: ChildrenDisplayMode {
        get {
            ChildrenDisplayMode(rawValue: childrenDisplayModeRaw) ?? .all
        }
        set {
            childrenDisplayModeRaw = newValue.rawValue
        }
    }
    
}

extension ActivityInstance: ParentModel {}
extension Trip: ParentModel {}
