//
//  LinkedParentInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

protocol LinkedParentInstance: AnyObject {
    var parentInstance: ActivityInstance? { get set }
    var parentInstanceRid: Int? { get set }
    
    func setParentInstance(_ newParent: ActivityInstance?)
}

extension LinkedParentInstance {
    func setParentInstance(_ newParent: ActivityInstance?) {
        parentInstance = newParent
        parentInstanceRid = newParent?.rid
    }
}

extension Trip: LinkedParentInstance {}
