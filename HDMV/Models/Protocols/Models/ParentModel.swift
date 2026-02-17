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
    
    var childActivities: [ActivityInstance] { get set }
    var childTrips: [Trip] { get set }
    var childInteractions: [Interaction] { get set }
    var childLifeEvents: [LifeEvent] { get set }
    
    var childrenDisplayModeRaw: String { get set }
    
}

extension ParentModel {
    
    func hasChildren() -> Bool {
        return !(self.childActivities.isEmpty) ||
        !(self.childTrips.isEmpty) ||
        !(self.childInteractions.isEmpty) ||
        !(self.childLifeEvents.isEmpty)
    }
    
    func hasOngoingChild() -> Bool {
        return hasOngoingTrips() || hasOngoingInteractions() || hasOngoingInstance()
    }
    
    func hasOngoingTrips() -> Bool {
        self.childTrips.contains { $0.timeEnd == nil }
    }
    
    func hasOngoingInteractions() -> Bool {
        self.childInteractions.contains { $0.timeEnd == nil }
    }
    
    func hasOngoingInstance() -> Bool {
        self.childActivities.contains { $0.timeEnd == nil }
    }
    
    var sortedChildren: [any LogModel] {
        var allChildren: [any LogModel] = []
        
        allChildren.append(contentsOf: self.childActivities)
        allChildren.append(contentsOf: self.childTrips)
        allChildren.append(contentsOf: self.childInteractions)
        allChildren.append(contentsOf: self.childLifeEvents)
        
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
                
        if childrenDisplayMode == .ongoing && hasOngoingChild() == false {
            advanceDisplayMode()
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
