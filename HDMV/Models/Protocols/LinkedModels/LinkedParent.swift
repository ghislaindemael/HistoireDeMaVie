//
//  LinkedParentInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

protocol LinkedParent {
    var parentInstance: ActivityInstance? { get set }
    var parentInstanceRid: Int? { get set }
    
    var parentTrip: Trip? { get set }
    var parentTripRid: Int? { get set }
    
    var hasAmbiguousParents: Bool { get }
}

extension LinkedParent {
    
    var hasAmbiguousParents: Bool {
        return (parentInstance != nil || parentInstanceRid != nil) && (parentTrip != nil || parentTripRid != nil)
    }

    mutating func setParentInstance(_ newParent: ActivityInstance?, fallbackRid: Int? = nil) {
        clearParents()
        parentInstance = newParent
        parentInstanceRid = newParent?.rid ?? fallbackRid
    }
    
    mutating func clearParentInstance() {
        parentInstance = nil
        parentInstanceRid = nil
    }
    
    mutating func setParentTrip(_ newParent: Trip?, fallbackRid: Int? = nil) {
        clearParents()
        parentTrip = newParent
        parentTripRid = newParent?.rid ?? fallbackRid
    }
    
    mutating func clearParentTrip() {
        parentTrip = nil
        parentTripRid = nil
    }
    
    mutating func setParent(_ newParent: (any ParentModel)?, fallbackRid: Int? = nil) {
        clearParents()
        
        if let instanceParent = newParent as? ActivityInstance {
            parentInstance = instanceParent
            parentInstanceRid = instanceParent.rid ?? fallbackRid
        } else if let tripParent = newParent as? Trip {
            parentTrip = tripParent
            parentTripRid = tripParent.rid ?? fallbackRid
        }
    }
    
    mutating func clearParents() {
        parentInstance = nil
        parentInstanceRid = nil
        parentTrip = nil
        parentTripRid = nil
    }
    
    func hasNoParent() -> Bool {
        return parentInstance == nil
            && parentInstanceRid == nil
            && parentTrip == nil
            && parentTripRid == nil
    }
    
    func isOrphaned() -> Bool {
        return parentInstance == nil
            && parentTrip == nil
    }
}

extension ActivityInstance: LinkedParent {}
extension Trip: LinkedParent {}
extension Interaction: LinkedParent {}
extension LifeEvent: LinkedParent {}
extension Quote: LinkedParent {}
