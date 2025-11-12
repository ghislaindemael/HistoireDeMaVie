//
//  LinkedCity.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

import SwiftUI
import SwiftData

protocol LinkedCity: AnyObject {
    
    var cityRid: Int? { get set }
    var city: City? { get set }
    
}

extension LinkedCity {
    
    func setCity(_ newCity: City?, fallbackRid: Int? = nil) {
        self.city = newCity
        self.cityRid = newCity?.rid ?? fallbackRid
    }
    
    func clearCity() {
        self.city = nil
        self.cityRid = nil
    }
    
}

extension Place: LinkedCity {}
extension Vehicle: LinkedCity {}

