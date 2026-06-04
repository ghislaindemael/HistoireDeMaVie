//
//  LinkedTransitLine.swift
//  HDMV
//

import SwiftUI
import SwiftData

protocol LinkedTransitLine: AnyObject {
    
    var transitLineRid: Int? { get set }
    var transitLine: TransitLine? { get set }
    
}

extension LinkedTransitLine {
    
    func setTransitLine(_ newLine: TransitLine?, fallbackRid: Int? = nil) {
        self.transitLine = newLine
        self.transitLineRid = newLine?.rid ?? fallbackRid
    }
    
    func clearTransitLine() {
        self.transitLine = nil
        self.transitLineRid = nil
    }
    
}

extension Trip: LinkedTransitLine {}
