//
//  ParentModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.11.2025.
//

import Foundation

protocol ParentModel: LogModel {
    
    var childActivities: [ActivityInstance]? { get set }
    var childTrips: [Trip]? { get set }
    var childInteractions: [Interaction]? { get set }
    var childLifeEvents: [LifeEvent]? { get set }
        
}

extension ParentModel {
    
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
    
}

extension ActivityInstance: ParentModel {}
extension Trip: ParentModel {}
