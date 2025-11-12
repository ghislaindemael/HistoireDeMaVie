//
//  LinkedParentInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

protocol LinkedParent: AnyObject {
    var parentInstance: ActivityInstance? { get set }
    var parentInstanceRid: Int? { get set }
    
    var parentTrip: Trip? { get set }
    var parentTripRid: Int? { get set }
}

extension LinkedParent {
    
    func setParentInstance(_ newParent: ActivityInstance?, fallbackRid: Int? = nil) {
        parentInstance = newParent
        parentInstanceRid = newParent?.rid ?? fallbackRid
    }
    
    func clearParentInstance() {
        parentInstance = nil
        parentInstanceRid = nil
    }
    
    func setParentTrip(_ newParent: Trip?, fallbackRid: Int? = nil) {
        parentTrip = newParent
        parentTripRid = newParent?.rid ?? fallbackRid
    }
    
    func clearParentTrip() {
        parentTrip = nil
        parentTripRid = nil
    }
    
    func setParent(_ newParent: (any ParentModel)?, fallbackRid: Int? = nil) {
        clearParents()
        
        if let instanceParent = newParent as? ActivityInstance {
            parentInstance = instanceParent
            parentInstanceRid = instanceParent.rid
        } else if let tripParent = newParent as? Trip {
            parentTrip = tripParent
            parentTripRid = tripParent.rid
        } else {
            parentInstanceRid = fallbackRid
            parentTripRid = fallbackRid
        }
    }
    
    func clearParents() {
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
