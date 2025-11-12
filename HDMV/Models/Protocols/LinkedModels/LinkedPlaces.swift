//
//  LinkedPlaces.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

import SwiftUI
import SwiftData

protocol LinkedPlaces: AnyObject {
    
    var placeStartRid: Int? { get set }
    var placeStart: Place? { get set }
    var placeEndRid: Int? { get set }
    var placeEnd: Place? { get set }
    
}

extension LinkedPlaces {
    
    func setPlaceStart(_ newPlace: Place?, fallbackRid: Int? = nil) {
        self.placeStart = newPlace
        self.placeStartRid = newPlace?.rid ?? fallbackRid
    }
    
    func clearPlaceStart() {
        self.placeStart = nil
        self.placeStartRid = nil
    }
    
    func setPlaceEnd(_ newPlace: Place?, fallbackRid: Int? = nil) {
        self.placeEnd = newPlace
        self.placeEndRid = newPlace?.rid ?? fallbackRid
    }
    
    func clearPlaceEnd() {
        self.placeEnd = nil
        self.placeEndRid = nil
    }
    
}

extension Trip: LinkedPlaces {}
extension Path: LinkedPlaces {}

