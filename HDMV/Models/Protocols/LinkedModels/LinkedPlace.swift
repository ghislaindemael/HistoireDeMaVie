//
//  LinkedPlace.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

import SwiftUI
import SwiftData

protocol LinkedPlace: AnyObject {
    
    var placeRid: Int? { get set }
    var place: Place? { get set }
    
}

extension LinkedPlace {
    
    func setPlace(_ newPlace: Place?, fallbackRid: Int? = nil) {
        self.place = newPlace
        self.placeRid = newPlace?.rid
    }
    
    func clearPlace() {
        self.place = nil
        self.placeRid = nil
    }
    
}

