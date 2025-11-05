//
//  LinkedParentInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

protocol LinkedParentInstance: AnyObject {
    var parentInstance: ActivityInstance? { get set }
    var parentInstanceRid: Int? { get set }
}

extension LinkedParentInstance {
    
    func setParentInstance(_ newParent: ActivityInstance?, fallbackRid: Int? = nil) {
        parentInstance = newParent
        parentInstanceRid = newParent?.rid ?? fallbackRid
    }
    
    func clearParentInstance() {
        parentInstance = nil
        parentInstanceRid = nil
    }
}

extension ActivityInstance: LinkedParentInstance {}
extension Trip: LinkedParentInstance {}
extension Interaction: LinkedParentInstance {}
extension LifeEvent: LinkedParentInstance {}
