//
//  LinkedCountry.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.11.2025.
//

import SwiftUI
import SwiftData

protocol LinkedCountry: AnyObject {
    
    var countryRid: Int? { get set }
    var country: Country? { get set }
    
}

extension LinkedCountry {
    
    func setCountry(_ newCountry: Country?, fallbackRid: Int? = nil) {
        self.country = newCountry
        self.countryRid = newCountry?.rid ?? fallbackRid
    }
    
    func clearCountry() {
        self.country = nil
        self.countryRid = nil
    }

    
}

extension City: LinkedCountry {}


