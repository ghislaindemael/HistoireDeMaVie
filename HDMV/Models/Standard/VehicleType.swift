//
//  VehicleType.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import Foundation
import SwiftData

enum VehicleType: String, CaseIterable, Codable {
    // The rawValue is now the lowercase slug, perfect for DB storage.
    case funiculaire = "funiculaire"
    case coach = "coach"
    case boat = "boat"
    case plane = "plane"
    case bus = "bus"
    case feet = "feet"
    case car = "car"
    case train = "train"
    case tram = "tram"
    case metro = "metro"
    case bike = "bike"
    case ski = "ski"
    case snowboard = "snowboard"
    case sled = "sled"
    case tractor = "tractor"
    case skateboard = "skateboard"
    case scooter = "scooter"
    case cablecar = "cablecar"
    case skilift = "skilift"
    
    var name: String {
        switch self {
            case .funiculaire: return "Funiculaire"
            case .coach: return "Car"
            case .boat: return "Bateau"
            case .plane: return "Avion"
            case .bus: return "Bus"
            case .feet: return "Feet"
            case .car: return "Voiture"
            case .train: return "Train"
            case .tram: return "Tram"
            case .metro: return "Métro"
            case .bike: return "Vélo"
            case .ski: return "Ski"
            case .snowboard: return "Snowboard"
            case .sled: return "Luge"
            case .tractor: return "Tracteur"
            case .skateboard: return "Skateboard"
            case .scooter: return "Trottinette"
            case .cablecar: return "Télécabine"
            case .skilift: return "Télésiège"
        }
    }
    
    var icon: String {
        switch self {
            case .funiculaire: return "🚇"
            case .coach: return "🚐"
            case .boat: return "🚢"
            case .plane: return "🛩️"
            case .bus: return "🚌"
            case .feet: return "👣"
            case .car: return "🚙"
            case .train: return "🚂"
            case .tram: return "🚈"
            case .metro: return "🚇"
            case .bike: return "🚲"
            case .ski: return "🎿"
            case .snowboard: return "🏂"
            case .sled: return "🛷"
            case .tractor: return "🚜"
            case .skateboard: return "🛹"
            case .scooter: return "🛴"
            case .cablecar: return "🚠"
            case .skilift: return "🚡"
        }
    }
    
    var label: String {
        return "\(self.icon) \(self.name)"
    }
}
