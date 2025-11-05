//
//  LinkedVehicle.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.11.2025.
//

import SwiftUI
import SwiftData

protocol LinkedVehicle: AnyObject {
    
    var vehicleRid: Int? { get set }
    var vehicle: Vehicle? { get set }
    
}

extension LinkedVehicle {
    
    func setVehicle(_ newVehicle: Vehicle?, fallbackRid: Int? = nil) {
        self.vehicle = newVehicle
        self.vehicleRid = newVehicle?.rid ?? fallbackRid
    }
    
    func clearVehicle() {
        self.vehicle = nil
        self.vehicleRid = nil
    }

    
}

extension Trip: LinkedVehicle {}


