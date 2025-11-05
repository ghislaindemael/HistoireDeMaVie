//
//  LinkedCity.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

import SwiftUI
import SwiftData

protocol LinkedPath: AnyObject {
    
    var pathRid: Int? { get set }
    var path: Path? { get set }
    
}

extension LinkedPath {
    
    func setPath(_ newPath: Path?, fallbackRid: Int? = nil) {
        self.path = newPath
        self.pathRid = newPath?.rid ?? fallbackRid
    }
    
    func clearPath() {
        self.path = nil
        self.pathRid = nil
    }
    
}

extension Trip: LinkedPath {}

