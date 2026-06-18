//
//  LinkedParentCity.swift
//  HDMV
//

import SwiftUI
import SwiftData

protocol LinkedParentCity: AnyObject {
    var parentRid: Int? { get set }
    var parentCity: City? { get set }
}

extension LinkedParentCity {
    func setParentCity(_ newParent: City?, fallbackRid: Int? = nil) {
        self.parentCity = newParent
        self.parentRid = newParent?.rid ?? fallbackRid
    }
    
    func clearParentCity() {
        self.parentCity = nil
        self.parentRid = nil
    }
}
